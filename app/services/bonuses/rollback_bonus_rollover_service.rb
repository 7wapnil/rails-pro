# frozen_string_literal: true

module Bonuses
  class RollbackBonusRolloverService < ApplicationService
    def initialize(bet:)
      @bet = bet
    end

    def call
      recalculate_rollover!
    end

    private

    attr_reader :bet

    def recalculate_rollover!
      return if bet.odd_value < customer_bonus.min_odds_per_bet

      customer_bonus.with_lock do
        balance = customer_bonus.rollover_balance
        customer_bonus.update!(rollover_balance: balance + rollover_amount)
      end
    end

    def customer_bonus
      @customer_bonus ||= bet.customer_bonus
    end

    def rollover_amount
      [customer_bonus.max_rollover_per_bet, bet.amount].min
    end
  end
end
