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
        customer_bonus.present? &&
        customer_bonus.active? && customer_bonus.sportsbook? &&
        bet_match_bonus_rules?
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

    def bet_match_bonus_rules?
      return false if bet.odd_value < customer_bonus.min_odds_per_bet
      return true unless combo_bets_rules?

      bet.bet_legs.all? do |bet_leg|
        bet_leg.odd_value >= customer_bonus.min_odds_per_bet
      end
    end

    def bet_rollover_amount
      [
        customer_bonus.max_rollover_per_bet,
        bet.amount * customer_bonus.sportsbook_multiplier
      ].min
    end

    def combo_bets_rules?
      bet.combo_bets? && customer_bonus.limit_per_each_bet_leg
    end
  end
end
