# frozen_string_literal: true

module CustomerBonuses
  class RollbackBonusRolloverService < ApplicationService
    def initialize(bet:)
      @bet = bet
    end

    def call
      return if bet.odd_value < customer_bonus.min_odds_per_bet

      customer_bonus.with_lock do
        balance = customer_bonus.rollover_balance
        customer_bonus.update!(rollover_balance: balance + rollover_amount)
      end
    end

    private

    attr_reader :bet

    delegate :customer_bonus, to: :bet

    def rollover_amount
      [customer_bonus.max_rollover_per_bet, bet.amount].min
    end
  end
end
