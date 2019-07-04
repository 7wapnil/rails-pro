# frozen_string_literal: true

module Customers
  class Summary < ApplicationRecord
    self.table_name = 'customer_summaries'

    REDUCE_COLUMNS = %w[bonus_wager_amount
                        real_money_wager_amount
                        bonus_payout_amount
                        real_money_payout_amount
                        bonus_deposit_amount
                        real_money_deposit_amount
                        withdraw_amount
                        signups_count
                        betting_customer_ids].freeze

    DERIVED_METHODS = %w[total_wager_amount
                         total_payout_amount
                         active_customers_count
                         bets_count
                         bonus_pnl_percentage
                         real_money_pnl_percentage
                         total_pnl_percentage].freeze

    REPORT_FIELDS = %w[bonus_wager_amount
                       real_money_wager_amount
                       bonus_payout_amount
                       real_money_payout_amount
                       total_wager_amount
                       total_payout_amount
                       bonus_deposit_amount
                       real_money_deposit_amount
                       bonus_pnl_percentage
                       real_money_pnl_percentage
                       total_pnl_percentage
                       withdraw_amount
                       signups_count
                       active_customers_count
                       bets_count].freeze
  end
end
