module BalanceCalculations
  class BetWithBonus < ApplicationService
    def initialize(bet, ratio)
      @bet = bet
      @ratio = ratio
    end

    def call
      {
        real_money: -calculate_real_amount,
        bonus: -calculate_bonus_amount
      }
    end

    private

    attr_reader :bet, :ratio

    def calculate_bonus_amount
      bet.amount - calculate_real_amount
    end

    def calculate_real_amount
      @calculate_real_amount ||= bet.amount * ratio
    end
  end
end
