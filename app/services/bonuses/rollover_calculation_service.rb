# fronzen_string_literal: true

module Bonuses
  class RolloverCalculationService < ApplicationService
    def initialize(customer_bonus:)
      @customer_bonus = customer_bonus
    end

    def call
      return unless customer_bonus

      recalculate_rollover!
    end

    attr_reader :customer_bonus

    private

    def recalculate_rollover!
      return unless customer_bonus

      balance = customer_bonus.rollover_initial_value
      bets = customer_bonus
             .bets
             .settled
             .where(void_factor: nil)
             .where('odd_value > ?', customer_bonus.min_odds_per_bet)

      balance -= bets.map { |bet| bet_rollover_amount(bet) }.sum
      customer_bonus.update!(rollover_balance: balance)
    end

    def bet_rollover_amount(bet)
      [customer_bonus.max_rollover_per_bet, bet.amount].min
    end
  end
end
