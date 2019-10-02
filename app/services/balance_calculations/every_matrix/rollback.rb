# frozen_string_literal: true

module BalanceCalculations
  module EveryMatrix
    class Rollback < BaseCalculations
      def call
        {
          real_money_amount: calculated_real_money_amount,
          bonus_amount: calculated_bonus_amount
        }
      end
    end
  end
end
