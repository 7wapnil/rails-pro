class AddFieldsToSummaries < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_summaries, :casino_customer_ids,
               :integer, null: false, array: true, default: []
    add_column :customer_summaries, :casino_bonus_wager_amount,
               :decimal, precision: 14, scale: 2, default: 0, null: false
    add_column :customer_summaries, :casino_real_money_wager_amount,
               :decimal, precision: 14, scale: 2, default: 0, null: false
    add_column :customer_summaries, :casino_bonus_payout_amount,
               :decimal, precision: 14, scale: 2, default: 0, null: false
    add_column :customer_summaries, :casino_real_money_payout_amount,
               :decimal, precision: 14, scale: 2, default: 0, null: false
  end
end
