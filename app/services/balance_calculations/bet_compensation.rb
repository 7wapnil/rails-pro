# frozen_string_literal: true

module BalanceCalculations
  class BetCompensation < ApplicationService
    delegate :placement_entry, to: :bet, allow_nil: true
    delegate :real_money_amount, :bonus_amount, to: :placement_entry,
                                                allow_nil: true

    def initialize(bet:, amount:)
      @bet = bet
      @amount = amount
    end

    def call
      return all_real_money if complete_bonus_bet?

      {
        real_money_amount: calculated_real_money_amount,
        bonus_amount: calculated_bonus_amount
      }
    end

    private

    attr_reader :bet, :amount

    def all_real_money
      { real_money_amount: amount }
    end

    def complete_bonus_bet?
      bet.customer_bonus&.completed?
    end

    def calculated_real_money_amount
      @calculated_real_money_amount ||= amount * ratio
    end

    def ratio
      RatioCalculator.call(
        real_money_amount: real_money_amount,
        bonus_amount: bonus_amount
      )
    end

    def calculated_bonus_amount
      amount - calculated_real_money_amount
    end
  end
end
