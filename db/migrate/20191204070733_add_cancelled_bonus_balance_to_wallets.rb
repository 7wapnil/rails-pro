class AddCancelledBonusBalanceToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :cancelled_bonus_balance,
               :decimal, precision: 14, scale: 2, default: 0
  end
end
