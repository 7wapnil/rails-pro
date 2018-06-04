class SetDefaultValueForAmount < ActiveRecord::Migration[5.2]
  def change
    change_column_default :wallets, :amount, from: nil, to: 0.0
    change_column_default :balances, :amount, from: nil, to: 0.0
  end
end
