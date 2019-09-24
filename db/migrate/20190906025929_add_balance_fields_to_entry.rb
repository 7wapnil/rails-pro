class AddBalanceFieldsToEntry < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength
    add_column :entries,
               :real_money_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries,
               :base_currency_real_money_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries,
               :bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries,
               :base_currency_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries,
               :bonus_amount_after,
               :decimal, precision: 14, scale: 2, default: 0

    execute balance_entry_to_entry_sql
  end

  def down
    remove_column :entries, :real_money_amount
    remove_column :entries, :base_currency_real_money_amount
    remove_column :entries, :bonus_amount
    remove_column :entries, :base_currency_bonus_amount
    remove_column :entries, :bonus_amount_after
  end

  private

  def balance_entry_to_entry_sql
    <<~SQL
      UPDATE entries
      SET real_money_amount = balance_entries.amount,
          base_currency_real_money_amount = balance_entries.base_currency_amount
      FROM entries EntriesScope
      INNER JOIN balance_entries
        ON balance_entries.entry_id = EntriesScope.id
      INNER JOIN balances
        ON balance_entries.balance_id = balances.id
      WHERE EntriesScope.id = entries.id AND balances.kind = 'real_money';

      UPDATE entries
      SET bonus_amount = balance_entries.amount,
          base_currency_bonus_amount = balance_entries.base_currency_amount
      FROM entries EntriesScope
      INNER JOIN balance_entries
        ON balance_entries.entry_id = EntriesScope.id
      INNER JOIN balances
        ON balance_entries.balance_id = balances.id
      WHERE EntriesScope.id = entries.id AND balances.kind = 'bonus'
    SQL
  end
end
