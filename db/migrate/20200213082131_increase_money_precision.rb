class IncreaseMoneyPrecision < ActiveRecord::Migration[5.2]
  OLD_PRECISION = 14
  OLD_SCALE = 2
  NEW_PRECISION = 17
  NEW_SCALE = 5
  MONEY_COLUMNS = {
    'bets' => %w[amount],
    'customer_bonuses' => %w[rollover_balance rollover_initial_value
                             total_confiscated_amount total_converted_amount],
    'customer_statistics' => %w[deposit_value withdrawal_value prematch_wager
                                prematch_payout live_sports_wager
                                live_sports_payout total_pending_bet_sum
                                total_bonus_awarded total_bonus_completed
                                casino_game_wager casino_game_payout
                                live_casino_wager live_casino_payout],
    'customer_summaries' => %w[bonus_wager_amount real_money_wager_amount
                               bonus_payout_amount real_money_payout_amount
                               bonus_deposit_amount real_money_deposit_amount
                               withdraw_amount casino_bonus_wager_amount
                               casino_real_money_wager_amount
                               casino_bonus_payout_amount
                               casino_real_money_payout_amount],
    'entries' => %w[amount balance_amount_after real_money_amount
                    base_currency_real_money_amount bonus_amount
                    base_currency_bonus_amount bonus_amount_after
                    confiscated_bonus_amount
                    base_currency_confiscated_bonus_amount
                    confiscated_bonus_amount_after
                    converted_bonus_amount
                    base_currency_converted_bonus_amount
                    converted_bonus_amount_after],
    'entry_currency_rules' => %w[min_amount max_amount],
    'entry_requests' => %w[amount real_money_amount bonus_amount
                           confiscated_bonus_amount converted_bonus_amount],
    'every_matrix_game_details' => %w[top_prize],
    'every_matrix_play_items' => %w[theoretical_payout third_party_fee fpp],
    'every_matrix_transactions' => %w[amount],
    'wallets' => %w[amount real_money_balance bonus_balance
                    confiscated_bonus_balance]
  }.freeze

  def up
    change_money_precision(NEW_PRECISION, NEW_SCALE)
  end

  def down
    change_money_precision(OLD_PRECISION, OLD_SCALE)
  end

  def change_money_precision(precision, scale)
    MONEY_COLUMNS.each_pair do |table, columns|
      columns.each do |column|
        change_column table, column, :decimal,
                      precision: precision,
                      scale: scale
      end
    end
  end
end
