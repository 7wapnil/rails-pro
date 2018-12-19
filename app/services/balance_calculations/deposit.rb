module BalanceCalculations
  class Deposit < ApplicationService
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
      min_deposit = bonus&.min_deposit
      return 0 if min_deposit.nil? || min_deposit > amount

      bonus_amount = amount * (bonus.percentage / 100.0)
      max_deposit_bonus = bonus.max_deposit_match
      bonus_amount > max_deposit_bonus ? max_deposit_bonus : bonus_amount
    end
  end
end
