# fronzen_string_literal: true

module CustomerBonuses
  class RolloverCalculationService < ApplicationService
    def initialize(bet)
      @bet = bet
      @customer_bonus = bet.customer_bonus
    end

    def call
      return unless eligible?

      tag_bet_rollover!
      recalculate_rollover!
    end

    private

    attr_reader :bet, :customer_bonus

    def eligible?
      bet.settled? &&
        customer_bonus && customer_bonus.active? &&
        bet.odd_value >= customer_bonus.min_odds_per_bet
    end

    def tag_bet_rollover!
      bet.update_attributes(counted_towards_rollover: true)
    end

    def recalculate_rollover!
      customer_bonus.with_lock do
        customer_bonus.rollover_balance -= bet_rollover_amount
        customer_bonus.save!
      end
    end

    def bet_rollover_amount
      [customer_bonus.max_rollover_per_bet, bet.amount].min
    end
  end
end
