class AddBaseCurrencyAmountToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :base_currency_amount, :decimal
  end
end
