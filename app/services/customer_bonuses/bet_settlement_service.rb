module CustomerBonuses
  class BetSettlementService < ApplicationService
    def initialize(bet:)
      @bet = bet
    end

    def call
      return unless customer_bonus&.active?

      recalculate_bonus_rollover
      complete_bonus if customer_bonus.rollover_balance.negative?

      return if unsettled_bets_remaining

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
        .perform_async(customer_bonus: bet.customer_bonus)
    end

    def lose_bonus
      return unless customer_bonus.active?

      customer_bonus.lose!
    end

    def unsettled_bets_remaining
      bonus_bets = Bet.where(customer_bonus: customer_bonus)
      bonus_bets.where(settlement_status: nil).exists?
    end
  end
end
