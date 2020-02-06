# frozen_string_literal: true

module CustomerBonuses
  class BetSettlementService < ApplicationService
    def initialize(bet)
      @bet = bet
      @customer_bonus = bet.customer_bonus
    end

    def call
      return unless customer_bonus&.active? && settled?

      recalculate_bonus_rollover unless bet.voided?
      return complete_bonus! if reached_rollover?

      lose_bonus! if lose_bonus?
    end

    private

    attr_reader :bet, :customer_bonus

    def settled?
      bet.settled? || bet.manually_settled? || bet.pending_manual_settlement?
    end

    def recalculate_bonus_rollover
      RolloverCalculationService.call(bet)
      customer_bonus.reload
    end

    def complete_bonus!
      Complete.call(customer_bonus: customer_bonus)
    end

    def lose_bonus!
      Deactivate.call(
        bonus: customer_bonus,
        action: Deactivate::LOSE
      )
    end

    def reached_rollover?
      customer_bonus.rollover_balance <= 0
    end

    def lose_bonus?
      return false if available_bonus_funds?

      no_pending_wagers? && no_pending_bets?
    end

    def available_bonus_funds?
      customer_bonus.wallet.bonus_balance.positive?
    end

    def no_pending_wagers?
      return true unless customer_bonus.casino?

      customer_bonus.wagers.pending_bonus_loss.none?
    end

    def no_pending_bets?
      return true unless customer_bonus.sportsbook?

      customer_bonus.bets.pending.none?
    end
  end
end
