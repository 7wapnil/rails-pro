# frozen_string_literal: true

module Customers
  class Summary < ApplicationRecord
    self.table_name = 'customer_summaries'

    def total_wager_amount
      bonus_wager_amount + real_money_wager_amount
    end

    def total_payout_amount
      bonus_payout_amount + real_money_payout_amount
    end

    def active_customers_count
      betting_customer_ids.unique.count
    end

    def bets_count
      betting_customer_ids.count
    end

    def bonus_pnl_percentage
      100.0 * (bonus_wager_amount - bonus_payout_amount) / bonus_wager_amount
    end

    def real_money_pnl_percentage
      100.0 * (real_money_wager_amount - real_money_payout_amount) /
        real_money_wager_amount
    end

    def total_pnl_percentage
      100.0 * (total_wager_amount - total_payout_amount) / total_wager_amount
    end
  end
end
