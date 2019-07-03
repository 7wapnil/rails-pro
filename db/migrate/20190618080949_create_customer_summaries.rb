class CreateCustomerSummaries < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :customer_summaries do |t|
      t.date :day, null: false
      t.decimal :bonus_wager_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.decimal :real_money_wager_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.decimal :bonus_payout_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.decimal :real_money_payout_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.decimal :bonus_deposit_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.decimal :real_money_deposit_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.decimal :withdraw_amount,
                precision: 8, scale: 2, null: false, default: 0
      t.integer :signups_count, null: false, default: 0
      t.integer :betting_customer_ids, null: false, array: true, default: []

      t.timestamps

      t.index [:day], unique: true
    end
  end
end
