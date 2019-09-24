class DropBalanceEntryRequest < ActiveRecord::Migration[5.2]
  def up
    drop_table :balance_entry_requests
  end

  def down
    create_table :balance_entry_requests do |t|
      t.references :entry_request, index: true
      t.references :balance_entry, index: true
      t.string :kind
      t.decimal :amount, precision: 14, scale: 2

      t.timestamps
    end

    add_index :balance_entry_requests, %i[entry_request_id kind], unique: true
    execute entry_request_to_balance_entry_request_sql
  end

  private

  def entry_request_to_balance_entry_request_sql
    <<~SQL
      INSERT INTO balance_entry_requests
        (entry_request_id, balance_entry_id, kind, amount, created_at,
         updated_at)
      SELECT
        entry_requests.id, balance_entries.id, balances.kind,
        CASE
          WHEN balances.kind = 'real_money' THEN entry_requests.real_money_amount
          ELSE entry_requests.bonus_amount
        END, entry_requests.created_at, entry_requests.updated_at
      FROM entry_requests
      INNER JOIN entries ON entries.entry_request_id = entry_requests.id
      INNER JOIN balance_entries ON balance_entries.entry_id = entries.id
      INNER JOIN balances ON balance_entries.balance_id = balances.id
      WHERE balances.kind = 'real_money' OR entry_requests.bonus_amount > 0
    SQL
  end
end
