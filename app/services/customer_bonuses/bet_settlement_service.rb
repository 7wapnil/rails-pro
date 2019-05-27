module CustomerBonuses
  class BetSettlementService < ApplicationService
    def initialize(bet:)
      @bet = bet
    end

    def call
      return unless customer_bonus&.active?

      recalculate_bonus_rollover
      complete_bonus unless customer_bonus.rollover_balance.positive?

      return if unsettled_bets_remaining || customer_bonus.completed?

      bonus_money_left = customer_bonus.wallet.bonus_balance&.amount
      lose_bonus unless bonus_money_left&.positive?
    end

    attr_reader :bet

    delegate :customer_bonus, to: :bet

    private

    def recalculate_bonus_rollover
      ::CustomerBonuses::RolloverCalculationService.call(
        customer_bonus: customer_bonus
      )
    end

    def complete_bonus
      CustomerBonuses::CompleteWorker
        .perform_async(customer_bonus: customer_bonus)
    end

    def lose_bonus
      return unless customer_bonus.active?

      # Other CustomerBonus deactivation processes
      # involve bonus balance conviscation. At this
      # point, there is nothing to confiscate.
      customer_bonus.lose!
    end

    def unsettled_bets_remaining
      customer_bonus.bets.where(settlement_status: nil).exists?
    end
  end
end
