# frozen_string_literal: true

module BalanceCalculations
  module EveryMatrix
    class CreditCalculations < BaseCalculations
      delegate :customer_bonus, to: :wallet, allow_nil: true

      def call
        transaction.update_columns(
          real_money_ratio: ratio,
          customer_bonus_id: (customer_bonus&.id if bonus?)
        )

        {
          real_money_amount: -calculated_real_money_amount,
          bonus_amount: -calculated_bonus_amount
        }
      end

      def ratio
        @ratio ||= if bonus?
                     real_money_balance / wallet_amount
                   else
                     REAL_MONEY_ONLY_RATIO
                   end
      end
    end
  end
end
