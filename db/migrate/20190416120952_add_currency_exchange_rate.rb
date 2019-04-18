class AddCurrencyExchangeRate < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :exchange_rate, :decimal, precision: 12, scale: 5
  end
end
