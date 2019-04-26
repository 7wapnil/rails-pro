# frozen_string_literal: true

module BalanceCalculations
  class Bet < ApplicationService
    FULL_RATIO = 1.0

    delegate :customer_bonus, to: :bet
    delegate :applied?, to: :customer_bonus, allow_nil: true, prefix: true
    delegate :real_money_balance, :bonus_balance, to: :wallet, allow_nil: true

    def initialize(bet:)
      @bet = bet
    end

    def call
      {
        real_money: -calculated_real_amount,
        bonus: -calculated_bonus_amount
      }
    end

    private

    attr_reader :bet

    def calculated_real_amount
      @calculated_real_amount ||= bet.amount * ratio
    end

    def ratio
      return FULL_RATIO unless customer_bonus_applied?

      RatioCalculator.call(
        real_money_amount: real_money_balance&.amount,
        bonus_amount: bonus_balance&.amount
      )
    end

    def wallet
      @wallet ||= Wallet.find_or_create_by(
        customer_id: bet.customer_id,
        currency_id: bet.currency_id
      )
    end

    def calculated_bonus_amount
      bet.amount - calculated_real_amount
    end
  end
end
