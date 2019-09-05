class ChangePrecisionForMoneyColumns < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    change_decimal :balance_entries, :amount
    change_decimal :balance_entries, :balance_amount_after
    change_decimal :balance_entry_requests, :amount
    change_decimal :balances, :amount
    change_decimal :customer_bonuses, :rollover_balance
    change_decimal :customer_bonuses, :rollover_initial_value
    change_decimal :customer_statistics, :deposit_value
    change_decimal :customer_statistics, :withdrawal_value
    change_decimal :customer_statistics, :prematch_wager
    change_decimal :customer_statistics, :prematch_payout
    change_decimal :customer_statistics, :live_sports_wager
    change_decimal :customer_statistics, :live_sports_payout
    change_decimal :customer_statistics, :total_pending_bet_sum
    change_decimal :customer_statistics, :total_bonus_awarded
    change_decimal :customer_statistics, :total_bonus_completed
    change_decimal :customer_summaries, :bonus_wager_amount
    change_decimal :customer_summaries, :real_money_wager_amount
    change_decimal :customer_summaries, :bonus_payout_amount
    change_decimal :customer_summaries, :real_money_payout_amount
    change_decimal :customer_summaries, :bonus_deposit_amount
    change_decimal :customer_summaries, :real_money_deposit_amount
    change_decimal :customer_summaries, :withdraw_amount
    change_decimal :entries, :amount
    change_decimal :entries, :balance_amount_after
    change_decimal :entry_currency_rules, :min_amount
    change_decimal :entry_currency_rules, :max_amount
    change_decimal :entry_requests, :amount
  end

  def down # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    rollback_decimal :balance_entries, :amount
    rollback_decimal :balance_entries, :balance_amount_after
    rollback_decimal :balance_entry_requests, :amount
    rollback_decimal :balances, :amount
    rollback_decimal :customer_bonuses, :rollover_balance
    rollback_decimal :customer_bonuses, :rollover_initial_value
    rollback_decimal :customer_statistics, :deposit_value
    rollback_decimal :customer_statistics, :withdrawal_value
    rollback_decimal :customer_statistics, :prematch_wager
    rollback_decimal :customer_statistics, :prematch_payout
    rollback_decimal :customer_statistics, :live_sports_wager
    rollback_decimal :customer_statistics, :live_sports_payout
    rollback_decimal :customer_statistics, :total_pending_bet_sum
    rollback_decimal :customer_statistics, :total_bonus_awarded
    rollback_decimal :customer_statistics, :total_bonus_completed
    rollback_decimal :customer_summaries, :bonus_wager_amount
    rollback_decimal :customer_summaries, :real_money_wager_amount
    rollback_decimal :customer_summaries, :bonus_payout_amount
    rollback_decimal :customer_summaries, :real_money_payout_amount
    rollback_decimal :customer_summaries, :bonus_deposit_amount
    rollback_decimal :customer_summaries, :real_money_deposit_amount
    rollback_decimal :customer_summaries, :withdraw_amount
    rollback_decimal :entries, :amount
    rollback_decimal :entries, :balance_amount_after
    rollback_decimal :entry_currency_rules, :min_amount
    rollback_decimal :entry_currency_rules, :max_amount
    rollback_decimal :entry_requests, :amount
  end

  private

  def change_decimal(table, field)
    change_column table, field, :decimal, precision: 14, scale: 2
  end

  def rollback_decimal(table, field)
    change_column table, field, :decimal, precision: 8, scale: 2
  end
end
