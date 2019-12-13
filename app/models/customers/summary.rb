# frozen_string_literal: true

module Customers
  class Summary < ApplicationRecord
    self.table_name = 'customer_summaries'

    REDUCE_COLUMNS = %w[bonus_wager_amount
                        real_money_wager_amount
                        bonus_payout_amount
                        real_money_payout_amount
                        casino_bonus_wager_amount
                        casino_real_money_wager_amount
                        casino_bonus_payout_amount
                        casino_real_money_payout_amount
                        bonus_deposit_amount
                        real_money_deposit_amount
                        withdraw_amount
                        signups_count
                        betting_customer_ids
                        casino_customer_ids].freeze

    DERIVED_METHODS = %w[total_bet_wager_amount
                         total_bet_payout_amount
                         total_casino_wager_amount
                         total_casino_payout_amount
                         ggr_casino_amount
                         ggr_casino_bonus_amount
                         total_ggr_amount
                         sports_ratio_by_ggr
                         casino_ratio_by_ggr
                         active_customers_count
                         active_casino_customers_count
                         bets_count
                         casino_games_count
                         bonus_pnl_percentage
                         real_money_pnl_percentage
                         total_pnl_percentage].freeze

    REPORT_FIELDS = %w[bonus_wager_amount
                       real_money_wager_amount
                       bonus_payout_amount
                       real_money_payout_amount
                       total_bet_wager_amount
                       total_bet_payout_amount
                       total_casino_wager_amount
                       total_casino_payout_amount
                       ggr_casino_amount
                       ggr_casino_bonus_amount
                       total_ggr_amount
                       sports_ratio_by_ggr
                       casino_ratio_by_ggr
                       bonus_deposit_amount
                       real_money_deposit_amount
                       bonus_pnl_percentage
                       real_money_pnl_percentage
                       total_pnl_percentage
                       withdraw_amount
                       signups_count
                       active_customers_count
                       active_casino_customers_count
                       bets_count
                       casino_games_count].freeze
  end
end
