# frozen_string_literal: true

module Bets
  class RollbackSettlement < ApplicationService
    include JobLogger

    delegate :customer_bonus, to: :bet

    def initialize(bet:)
      @bet = bet
    end

    def call
      ActiveRecord::Base.transaction do
        bet.lock!

        validate_bet_status!
        rollback_money_and_bonuses! if bet.settled?
        revert_bet_status
      end
    end

    private

    attr_reader :bet, :entry_request

    def validate_bet_status!
      return if bet.settled? || bet.pending_manual_settlement?

      raise 'Bet has not been sent to settlement yet'
    end

    def rollback_money_and_bonuses!
      rollback_money
      rollback_bonus_rollover! if customer_bonus
    end

    def rollback_money
      entry_request = create_rollback_entry_request

      return unless entry_request

      EntryRequests::ProcessingService.call(entry_request: entry_request)
    end

    def create_rollback_entry_request
      return EntryRequests::Factories::Rollback.call(bet: bet) if bet.won?

      EntryRequests::Factories::RollbackBetRefund.call(bet: bet) if bet.voided?
    end

    def rollback_bonus_rollover!
      return bonus_for_wrong_customer! if bonus_for_wrong_customer?

      CustomerBonuses::RollbackBonusRolloverService.call(bet: bet)
    end

    def bonus_for_wrong_customer?
      bet.customer != customer_bonus.customer
    end

    def bonus_for_wrong_customer!
      raise I18n.t('errors.messages.bonus_for_wrong_customer')
    end

    def revert_bet_status
      bet.update!(
        settlement_status: nil,
        status: StateMachines::BetStateMachine::ACCEPTED,
        void_factor: nil
      )
    end
  end
end
