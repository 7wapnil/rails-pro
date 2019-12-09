# frozen_string_literal: true

module Bets
  class RollbackSettlement < ApplicationService
    include JobLogger

    FACTORIES = EntryRequests::Factories

    delegate :customer_bonus, to: :bet

    def initialize(bet_leg:)
      @bet_leg = bet_leg
      @bet = bet_leg.bet
    end

    def call
      ActiveRecord::Base.transaction do
        lock_important_entities!

        validate_bet_status!
        validate_bet_leg_status!
        rollback_money_and_bonuses! if bet.settled?
        revert_bet_leg_status
        revert_bet_status unless bet.accepted?
      end
    end

    private

    attr_reader :bet_leg, :bet, :entry_request

    def lock_important_entities!
      bet.lock!
      bet_leg.lock!
    end

    def validate_bet_status!
      return if bet.accepted? || bet.settled? || bet.pending_manual_settlement?

      raise 'Bet has not been sent to settlement yet/was not accepted'
    end

    def validate_bet_leg_status!
      return unless bet.status.nil?

      raise 'Bet leg has not been sent to settlement yet'
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
      return FACTORIES::Rollback.call(bet_leg: bet_leg) if bet.won?

      FACTORIES::RollbackBetRefund.call(bet_leg: bet_leg) if bet.voided?
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

    def revert_bet_leg_status
      bet_leg.update(settlement_status: nil)
    end

    def revert_bet_status
      bet.rollback_settlement!
    end
  end
end
