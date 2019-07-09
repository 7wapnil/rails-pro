# fronzen_string_literal: true

module CustomerBonuses
  class RolloverCalculationService < ApplicationService
    def initialize(bet)
      @bet = bet
      @bonus = bet.customer_bonus
    end

    def call
      return unless eligible?

      tag_bet_rollover!
      recalculate_rollover!
    end

    private

    attr_reader :bet, :bonus

    def eligible?
      bet.settled? &&
        bonus && bonus.active? &&
        bet.odd_value >= bonus.min_odds_per_bet
    end

    def tag_bet_rollover!
      bet.update_attributes(counted_towards_rollover: true)
    end

    def recalculate_rollover!
      bonus.update_attributes(rollover_balance: rollover_balance)
    end

    def rollover_balance
      amounts = Bet.where(
        customer_bonus: bonus,
        status: :settled,
        counted_towards_rollover: true
      ).pluck(:amount)

      max_rollover = bonus.max_rollover_per_bet

      bonus.rollover_initial_value -
        amounts.map { |amount| [max_rollover, amount].min }.sum
    end
  end
end
