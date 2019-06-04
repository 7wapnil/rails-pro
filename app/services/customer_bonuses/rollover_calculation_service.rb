# fronzen_string_literal: true

module CustomerBonuses
  class RolloverCalculationService < ApplicationService
    def initialize(bet:)
      @bet = bet
    end

    def call
      return unless bet.settled?

      return unless bet&.customer_bonus&.active?

      recalculate_rollover!
    end

    attr_reader :bet
    delegate :customer_bonus, to: :bet

    private

    def recalculate_rollover!
      return if bet.odd_value < customer_bonus.min_odds_per_bet

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
