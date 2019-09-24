class DropBalanceEntry < ActiveRecord::Migration[5.2]
  def up
    drop_table :balance_entries
  end

  def down
    create_table :balance_entries do |t|
      t.references :balance, foreign_key: true
      t.references :entry, foreign_key: true
      t.decimal :amount, precision: 14, scale: 2
      t.decimal :balance_amount_after, precision: 14, scale: 2
      t.decimal :base_currency_amount

      t.timestamps
    end
    execute entry_to_balance_entry_sql
  end

  private

  def entry_to_balance_entry_sql
    <<~SQL
      INSERT INTO balance_entries
        (balance_id, entry_id, amount, balance_amount_after,
         base_currency_amount, created_at, updated_at)
      SELECT
        balances.id, entries.id,
        CASE
          WHEN balances.kind = 'real_money' THEN entries.real_money_amount
          ELSE entries.bonus_amount
        END,
        CASE
          WHEN balances.kind = 'real_money'
            THEN entries.balance_amount_after - entries.bonus_amount_after
          ELSE entries.bonus_amount_after
        END,
        CASE
          WHEN balances.kind = 'real_money'
            THEN entries.base_currency_real_money_amount
          ELSE entries.base_currency_bonus_amount
        END,
        entries.created_at, entries.updated_at
      FROM entries
      INNER JOIN wallets ON entries.wallet_id = wallets.id
      INNER JOIN balances ON balances.wallet_id = wallets.id
      WHERE balances.kind = 'real_money' OR entries.bonus_amount > 0;
    SQL
  end
end
