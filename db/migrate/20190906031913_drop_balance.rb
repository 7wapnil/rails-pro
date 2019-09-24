class DropBalance < ActiveRecord::Migration[5.2]
  def up
    drop_table :balances
  end

  def down
    create_table :balances do |t|
      t.references :wallet, foreign_key: true
      t.string :kind
      t.decimal :amount, precision: 14, scale: 2

      t.timestamps
    end
    execute wallet_to_balance_sql
  end

  private

  def wallet_to_balance_sql
    <<~SQL
      INSERT INTO balances
        (wallet_id, kind, amount, created_at, updated_at)
      SELECT
        wallets.id, 'real_money', wallets.real_money_balance,
        wallets.created_at, wallets.updated_at
      FROM wallets
      UNION ALL
      SELECT
        wallets.id, 'bonus', wallets.bonus_balance,
        wallets.created_at, wallets.updated_at
      FROM wallets;
    SQL
  end
end
