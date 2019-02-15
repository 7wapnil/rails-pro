module BalanceCalculations
  class Deposit < ApplicationService
    delegate :min_deposit, to: :bonus, allow_nil: true

    def initialize(bonus, deposit_amount)
      @amount = deposit_amount
      @bonus = bonus
    end

    def call
      {
        real_money: amount,
        bonus: calculate_bonus_amount
      }
    end

    private

    attr_reader :bonus, :amount

    def calculate_bonus_amount
      return 0.0 unless valid_bonus?

      bonus_amount > max_deposit_bonus ? max_deposit_bonus : bonus_amount
    end

    def valid_bonus?
      min_deposit.present? && amount >= min_deposit
    end

    def bonus_amount
      @bonus_amount ||= amount * (bonus.percentage / 100.0)
    end

    def max_deposit_bonus
      @max_deposit_bonus ||= bonus.max_deposit_match
    end
  end
end
