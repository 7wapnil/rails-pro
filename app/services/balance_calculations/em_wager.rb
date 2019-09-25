# frozen_string_literal: true

module BalanceCalculations
  class EmWager < ApplicationService
    MONEY_PRECISION = 2

    delegate :wallet, to: :wager
    delegate :real_money_balance, :bonus_balance, to: :wallet, allow_nil: true

    def initialize(wager:)
      @wager = wager
    end

    def call
      {
        real_money: -calculated_real_amount,
        bonus: -calculated_bonus_amount
      }
    end

    private

    attr_reader :wager

    def calculated_real_amount
      @calculated_real_amount ||= (wager.amount * ratio).round(MONEY_PRECISION)
    end

    def ratio
      RatioCalculator.call(
        real_money_amount: real_money_balance&.amount,
        bonus_amount: bonus_balance&.amount
      )
    end

    def calculated_bonus_amount
      wager.amount - calculated_real_amount
    end
  end
end
