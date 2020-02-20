class AddMonthlyBalanceQueryResults < ActiveRecord::Migration[5.2]
  def change
    create_table :monthly_balance_query_results do |t|
      t.decimal :real_money_balance_eur, precision: 17, scale: 5
      t.decimal :bonus_amount_balance_eur, precision: 17, scale: 5
      t.decimal :total_balance_eur, precision: 17, scale: 5

      t.timestamps
    end
  end
end
