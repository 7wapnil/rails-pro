class AddBalanceFieldsToWallets < ActiveRecord::Migration[5.2]
  def up
    add_column :wallets,
               :real_money_balance,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :wallets,
               :bonus_balance,
               :decimal, precision: 14, scale: 2, default: 0
    execute balance_to_wallet_sql
  end

  def down
    remove_column :wallets, :real_money_balance, :decimal
    remove_column :wallets, :bonus_balance, :decimal
  end

  private

  def balance_to_wallet_sql
    <<~SQL
      UPDATE wallets
      SET real_money_balance =
            CASE
              WHEN real_balances.id IS NOT NULL
                THEN real_balances.amount
              ELSE WalletsScope.real_money_balance
            END,
          bonus_balance =
            CASE
              WHEN bonus_balances.id IS NOT NULL
                THEN bonus_balances.amount
              ELSE WalletsScope.bonus_balance
            END
      FROM wallets WalletsScope
      LEFT JOIN balances real_balances
        ON real_balances.wallet_id = WalletsScope.id AND
           real_balances.kind = 'real_money'
      LEFT JOIN balances bonus_balances
        ON bonus_balances.wallet_id = WalletsScope.id AND
           bonus_balances.kind = 'bonus'
      WHERE WalletsScope.id = wallets.id
    SQL
  end
end
