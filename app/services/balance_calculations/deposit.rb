module BalanceCalculations
  class Deposit < ApplicationService
    def initialize(wallet, deposit_amount)
      @amount = deposit_amount
      @customer = wallet.customer
    end

    def call
      {
        real_money: calculate_real_amount,
        bonus: calculate_bonus_amount
      }
    end

    private

    attr_reader :customer, :amount

    def calculate_bonus_amount
      bonus = customer.customer_bonus
      return unless bonus

      bonus_amount = amount * (bonus.percentage / 100.0)
      max_deposit_bonus = bonus.max_deposit_match
      bonus_amount > max_deposit_bonus ? max_deposit_bonus : bonus_amount
    end

    def calculate_real_amount
      amount
    end
  end
end
