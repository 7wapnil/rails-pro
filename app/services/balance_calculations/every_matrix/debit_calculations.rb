# frozen_string_literal: true

module BalanceCalculations
  module EveryMatrix
    class DebitCalculations < BaseCalculations
      delegate :wager, to: :transaction, allow_nil: true
      delegate :customer_bonus, to: :wager, allow_nil: true

      def call
        update_transaction

        {
          real_money_amount: calculated_real_money_amount,
          bonus_amount: calculated_bonus_amount,
          confiscated_bonus_amount: calculated_confiscated_bonus_amount
        }
      end

      private

      def update_transaction
        transaction.update_columns(
          real_money_ratio: ratio,
          customer_bonus_id: transaction.wager&.customer_bonus&.id
        )
      end

      def ratio
        @ratio ||=
          if all_to_real_money?
            REAL_MONEY_ONLY_RATIO
          else
            transaction.wager&.real_money_ratio
          end
      end

      def all_to_real_money?
        bonus_completed? ||
          !transaction.wager&.real_money_ratio
      end

      def calculated_bonus_amount
        return bonus_amount if bonus?

        log_cancelled_bonus if bonus_amount.positive?

        0
      end

      def calculated_confiscated_bonus_amount
        return bonus_amount unless bonus?

        0
      end

      def bonus_amount
        @bonus_amount ||=
          transaction.amount - calculated_real_money_amount
      end

      def log_cancelled_bonus
        Rails.logger.info(
          message: 'EveryMatrix Wallet API cancelled bonus',
          bonus_amount: bonus_amount,
          transaction: transaction.attributes,
          wager: wager.attributes,
          customer_bonus: customer_bonus.attributes
        )
      end
    end
  end
end
