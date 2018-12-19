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
      @ratio ||= begin
        bonus_balance_amount = wallet.bonus_balance&.amount || 0
        real_balance_amount = wallet.real_money_balance&.amount || 0
        customer_bonus = wallet.customer.customer_bonus

        return 1 if customer_bonus.nil? || customer_bonus.expired?

        total_balance = bonus_balance_amount + real_balance_amount
        real_balance_amount / total_balance
      end
    end

    private

    attr_reader :wallet, :amount

    def calculate_bonus_amount
      amount - calculate_real_amount
    end

    def calculate_real_amount
      amount * ratio
    end
  end
end
