class AddBalanceAmountAfterToBalanceEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :balance_entries, :balance_amount_after,
               :decimal, precision: 8, scale: 2
  end
end
