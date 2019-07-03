# frozen_string_literal: true

module Customers
  module Summaries
    module DerivedMethods
      def total_wager_amount
        bonus_wager_amount.to_f + real_money_wager_amount.to_f
      end

      def total_payout_amount
        bonus_payout_amount.to_f + real_money_payout_amount.to_f
      end

      def active_customers_count
        betting_customer_ids&.uniq&.count.to_i
      end

      def bets_count
        betting_customer_ids&.count.to_i
      end

      def bonus_pnl_percentage
        100.0 * (bonus_wager_amount.to_f - bonus_payout_amount.to_f) /
          bonus_wager_amount.to_f
      end

      def real_money_pnl_percentage
        100.0 * (real_money_wager_amount.to_f - real_money_payout_amount.to_f) /
          real_money_wager_amount.to_f
      end

      def total_pnl_percentage
        100.0 * (total_wager_amount.to_f - total_payout_amount.to_f) /
          total_wager_amount.to_f
      end
    end
  end
end
