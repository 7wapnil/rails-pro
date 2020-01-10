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
        validate_entities!

        rollback_money! if rollback_money?
        rollback_bonus_rollover! if rollback_bonus?
        rollback_bet_leg_status!
        update_bet_status!
      end
    end

    private

    attr_reader :bet_leg, :bet, :entry_request

    def lock_important_entities!
      bet.lock!
      bet_leg.lock!
      customer_bonus&.lock!
    end

    def validate_entities!
      validate_bet_status!
      validate_bet_leg_status!
    end

    def rollback_money?
      bet.settled? && (bet.won? || bet.voided?)
    end

    def rollback_money!
      entry_request = create_rollback_entry_request

      return unless entry_request

      EntryRequests::ProcessingService.call(entry_request: entry_request)
    end

    def rollback_bonus?
      bet.settled? && bet.won? || bet.lost? && !still_lose_bet?
    end

    def rollback_bonus_rollover!
      return unless customer_bonus
      return bonus_for_wrong_customer! if bonus_for_wrong_customer?

      CustomerBonuses::RollbackBonusRolloverService.call(bet: bet)
    end

    def rollback_bet_leg_status!
      bet_leg.update!(settlement_status: nil, status: nil)
    end

    def update_bet_status!
      return bet.resend_to_manual_settlement! if pending_manual_settlement?
      return bet.settle!(settlement_status: Bet::LOST) if approve_lose?

      bet.rollback_settlement! if rollback_to_acceptance?
    end

    def validate_bet_status!
      return if bet.accepted? || bet.settled? || bet.pending_manual_settlement?

      raise 'Bet has not been sent to settlement yet/was not accepted'
    end

    def validate_bet_leg_status!
      return unless bet.status.nil?

      raise 'Bet leg has not been sent to settlement yet'
    end

    def still_lose_bet?
      bet.bet_legs
         .reject { |leg| leg.id == bet_leg.id }
         .any?(&:lost?)
    end

    def bonus_for_wrong_customer?
      bet.customer != customer_bonus.customer
    end

    def bonus_for_wrong_customer!
      raise I18n.t('errors.messages.bonus_for_wrong_customer')
    end

    def pending_manual_settlement?
      unresolved_bet_legs? && !still_lose_bet?
    end

    def approve_lose?
      return false if bet.settled? && bet.lost?

      !unresolved_bet_legs? && still_lose_bet?
    end

    def rollback_to_acceptance?
      return true if bet.settled? && !still_lose_bet?
      return false if bet.accepted?

      !unresolved_bet_legs? && !still_lose_bet?
    end

    def unresolved_bet_legs?
      bet.bet_legs
         .reject { |leg| leg.id == bet_leg.id }
         .any?(&:pending_manual_settlement?)
    end

    def create_rollback_entry_request
      return FACTORIES::Rollback.call(bet_leg: bet_leg) if bet.won?

      FACTORIES::RollbackBetRefund.call(bet_leg: bet_leg) if bet.voided?
    end
  end
end
