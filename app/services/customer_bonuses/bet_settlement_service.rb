# frozen_string_literal: true

module CustomerBonuses
  class BetSettlementService < ApplicationService
    def initialize(bet)
      @bet = bet
      @customer_bonus = bet.customer_bonus
    end

    def call
      return unless customer_bonus&.active? && bet.settled?

      recalculate_bonus_rollover

      return complete_bonus! if complete_bonus?

      lose_bonus! if lose_bonus?
    end

    private

    attr_reader :bet, :customer_bonus

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

    def complete_bonus?
      customer_bonus.rollover_balance <= 0
    end

    def lose_bonus?
      customer_bonus.wallet.bonus_balance.amount <= 0 &&
        customer_bonus.active? &&
        customer_bonus.rollover_balance.positive? &&
        Bet.pending.where(customer_bonus: customer_bonus).none?
    end
  end
end
