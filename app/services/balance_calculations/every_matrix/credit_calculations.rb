# frozen_string_literal: true

module BalanceCalculations
  module EveryMatrix
    class CreditCalculations < BaseCalculations
      delegate :customer_bonus, to: :wallet, allow_nil: true

      def call
        update_transaction

        {
          real_money_amount: -calculated_real_money_amount,
          bonus_amount: -calculated_bonus_amount
        }
      end

      private

      def bonus?
        super && wallet.bonus_balance.positive?
      end

      def update_transaction
        transaction.update_columns(
          real_money_ratio: ratio,
          customer_bonus_id: (customer_bonus&.id if bonus?)
        )
      end

      def ratio
        @ratio ||= calculate_ratio
      end

      def calculate_ratio
        if bonus?
          real_money_balance / wallet_amount
        else
          REAL_MONEY_ONLY_RATIO
        end
      end
    end
  end
end
