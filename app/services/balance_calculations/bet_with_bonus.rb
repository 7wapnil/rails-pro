module BalanceCalculations
  class BetWithBonus < ApplicationService
    def initialize(wallet, bet_amount)
      @amount = bet_amount
      @wallet = wallet
    end

    def call
      {
        real_money: calculate_real_amount,
        bonus: calculate_bonus_amount
      }
    end

    def ratio
      bonus_balance_amount = wallet.bonus_balance&.amount
      real_balance_amount = wallet.real_money_balance&.amount
      customer_bonus = wallet.customer.customer_bonus

      return 1 if customer_bonus.nil? || customer_bonus.expired?

      return 0 unless bonus_balance_amount || real_balance_amount

      bonus_balance_amount ||= 0
      real_balance_amount ||= 0
      total_balance = bonus_balance_amount + real_balance_amount
      real_balance_amount / total_balance
    end

    private

    attr_reader :wallet, :amount

    def calculate_bonus_amount
      amount * (1.0 - ratio)
    end

    def calculate_real_amount
      amount * ratio
    end
  end
end
