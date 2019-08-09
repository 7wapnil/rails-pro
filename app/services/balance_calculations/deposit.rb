# frozen_string_literal: true

module BalanceCalculations
  class Deposit < ApplicationService
    delegate :min_deposit, to: :bonus, allow_nil: true

    def initialize(deposit_amount, currency, bonus, **params)
      @amount = deposit_amount
      @currency = currency
      @bonus = bonus
      @no_bonus = params[:no_bonus] || false
    end

    def call
      {
        real_money: amount,
        bonus: calculate_bonus_amount
      }
    end

    private

    attr_reader :bonus, :amount, :currency, :no_bonus

    def calculate_bonus_amount
      return 0.0 if no_bonus?
      return 0.0 unless valid_bonus?

      bonus_amount > max_deposit_bonus ? max_deposit_bonus : bonus_amount
    end

    def no_bonus?
      no_bonus.present?
    end

    def valid_bonus?
      min_deposit.present? && amount >= min_deposit
    end

    def bonus_amount
      @bonus_amount ||= amount * (bonus.percentage / 100.0)
    end

    def max_deposit_bonus
      @max_deposit_bonus ||= Exchanger::Converter.call(
        bonus.max_deposit_match,
        Currency.primary,
        currency
      )
    end
  end
end
