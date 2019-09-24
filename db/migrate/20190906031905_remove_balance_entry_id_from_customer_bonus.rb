class RemoveBalanceEntryIdFromCustomerBonus < ActiveRecord::Migration[5.2]
  def up
    execute balance_entry_to_entry_reference_sql
    remove_reference :customer_bonuses,
                     :balance_entry,
                     index: true,
                     foreign_key: true
  end

  def down
    add_reference :customer_bonuses,
                  :balance_entry,
                  index: true,
                  foreign_key: true
    execute entry_to_balance_entry_reference_sql
  end

  private

  def balance_entry_to_entry_reference_sql
    <<~SQL
      UPDATE customer_bonuses CB
      SET entry_id = entries.id
      FROM customer_bonuses CBScope
      INNER JOIN balance_entries
        ON CBScope.balance_entry_id = balance_entries.id
      INNER JOIN entries
        ON balance_entries.entry_id = entries.id
      WHERE CBScope.id = CB.id
    SQL
  end

  def entry_to_balance_entry_reference_sql
    <<~SQL
      UPDATE customer_bonuses CB
      SET balance_entry_id = balance_entries.id
      FROM customer_bonuses CBScope
      INNER JOIN entries
        ON CBScope.entry_id = entries.id
      INNER JOIN balance_entries
        ON entries.id = balance_entries.entry_id
      INNER JOIN balances
        ON balances.id = balance_entries.balance_id
      WHERE CBScope.id = CB.id AND balances.kind = 'bonus'
    SQL
  end
end
