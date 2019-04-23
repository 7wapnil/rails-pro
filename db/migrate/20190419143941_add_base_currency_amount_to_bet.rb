class AddBaseCurrencyAmountToBet < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :base_currency_amount, :decimal
  end
end
