# frozen_string_literal: true

module Customers
  module Summaries
    module DerivedMethods
      MONEY_PRECISION = 2
      PNL_PRECISION = 2
      def total_bet_wager_amount
        (
          bonus_wager_amount.to_f + real_money_wager_amount.to_f
        ).truncate(MONEY_PRECISION).to_d
      end

      def total_bet_payout_amount
        (
          bonus_payout_amount.to_f + real_money_payout_amount.to_f
        ).truncate(MONEY_PRECISION).to_d
      end

      def total_casino_wager_amount
        (
          casino_bonus_wager_amount.to_f + casino_real_money_wager_amount.to_f
        ).truncate(MONEY_PRECISION).to_d
      end

      def total_casino_payout_amount
        (
          casino_bonus_payout_amount.to_f + casino_real_money_payout_amount.to_f
        ).truncate(MONEY_PRECISION).to_d
      end

      def sports_ggr_amount
        (
          total_bet_wager_amount - total_bet_payout_amount
        ).truncate(MONEY_PRECISION).to_d
      end

      def ggr_casino_amount
        (
          total_casino_wager_amount - total_casino_payout_amount
        ).truncate(MONEY_PRECISION).to_d
      end

      def ggr_casino_bonus_amount
        (
          casino_bonus_wager_amount - casino_bonus_payout_amount
        ).truncate(MONEY_PRECISION).to_d
      end

      def sports_ratio_by_ggr
        (
          sports_ggr_amount / (sports_ggr_amount + ggr_casino_amount)
        ).truncate(PNL_PRECISION).to_d
      end

      def casino_ratio_by_ggr
        (
          ggr_casino_amount / (sports_ggr_amount + ggr_casino_amount)
        ).truncate(PNL_PRECISION).to_d
      end

      def total_ggr_amount
        total_wager = total_bet_wager_amount + total_casino_wager_amount
        total_payout = total_bet_payout_amount + total_casino_payout_amount

        (total_wager - total_payout).truncate(MONEY_PRECISION).to_d
      end

      def active_customers_count
        (betting_customer_ids + casino_customer_ids).uniq.count
      end

      def active_sports_customers_count
        betting_customer_ids.uniq.count
      end

      def active_casino_customers_count
        casino_customer_ids.uniq.count
      end

      def bets_count
        betting_customer_ids.count
      end

      def casino_games_count
        casino_customer_ids.count
      end

      def bonus_pnl_percentage
        format_pnl(
          100.0 *
          (bonus_wager_amount.to_f - bonus_payout_amount.to_f) /
          bonus_wager_amount.to_f
        )
      end

      def real_money_pnl_percentage
        format_pnl(
          100.0 *
          (real_money_wager_amount.to_f - real_money_payout_amount.to_f) /
          real_money_wager_amount.to_f
        )
      end

      def total_pnl_percentage
        format_pnl(
          100.0 *
          (total_bet_wager_amount.to_f - total_bet_payout_amount.to_f) /
          total_bet_wager_amount.to_f
        )
      end

      private

      def format_pnl(value)
        return '-' if value.nan? || value.infinite?

        value.truncate(PNL_PRECISION).to_d
      end
    end
  end
end
