# frozen_string_literal: true

module BalanceCalculations
  class BetCompensation < ApplicationService
    MONEY_PRECISION = 2

    delegate :placement_entry, to: :bet, allow_nil: true
    delegate :real_money_amount, :bonus_amount, to: :placement_entry,
                                                allow_nil: true

    def initialize(bet:, amount:)
      @bet = bet
      @amount = amount.round(MONEY_PRECISION)
    end

    def call
      {
        amount: amount,
        real_money_amount: calculated_real_money_amount,
        bonus_amount: calculated_bonus_amount
      }
    end

    private

    attr_reader :bet, :amount

    def calculated_real_money_amount
      @calculated_real_money_amount ||= (amount * ratio).round(MONEY_PRECISION)
    end

    def calculated_bonus_amount
      amount - calculated_real_money_amount
    end

    def ratio
      RatioCalculator.call(
        real_money_amount: real_money_amount,
        bonus_amount: bonus_amount
      )
    end
  end
end
