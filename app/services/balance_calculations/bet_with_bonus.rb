module BalanceCalculations
  class BetWithBonus < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def call
      {
        real_money: calculate_real_amount,
        bonus: calculate_bonus_amount
      }
    end

    private

    attr_reader :bet

    def calculate_bonus_amount
      bet.amount - calculate_real_amount
    end

    def calculate_real_amount
      bet.amount * bet.ratio
    end
  end
end
