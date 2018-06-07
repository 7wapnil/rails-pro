class AddCurrencyToWallets < ActiveRecord::Migration[5.2]
  def change
    remove_column :wallets, :currency, :integer
    add_reference :wallets, :currency, foreign_key: true
  end
end
