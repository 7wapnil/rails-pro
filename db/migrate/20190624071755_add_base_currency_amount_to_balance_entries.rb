class AddBaseCurrencyAmountToBalanceEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :balance_entries, :base_currency_amount, :decimal
  end
end
