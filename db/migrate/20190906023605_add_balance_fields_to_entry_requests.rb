class AddBalanceFieldsToEntryRequests < ActiveRecord::Migration[5.2]
  def up
    add_column :entry_requests,
               :real_money_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entry_requests,
               :bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0

    execute balance_entry_request_to_entry_request_sql
  end

  def down
    remove_column :entry_requests, :real_money_amount, :decimal
    remove_column :entry_requests, :bonus_amount, :decimal
  end

  private

  def balance_entry_request_to_entry_request_sql
    <<~SQL
      UPDATE entry_requests ER
      SET real_money_amount =
            CASE
              WHEN real_balance_entry_requests.id IS NOT NULL
                THEN real_balance_entry_requests.amount
              ELSE ERScope.real_money_amount
            END,
          bonus_amount =
            CASE
              WHEN bonus_balance_entry_requests.id IS NOT NULL
                THEN bonus_balance_entry_requests.amount
              ELSE ERScope.bonus_amount
            END
      FROM entry_requests ERScope
      LEFT JOIN balance_entry_requests real_balance_entry_requests
        ON real_balance_entry_requests.entry_request_id = ERScope.id AND
           real_balance_entry_requests.kind = 'real_money'
      LEFT JOIN balance_entry_requests bonus_balance_entry_requests
        ON bonus_balance_entry_requests.entry_request_id = ERScope.id AND
           bonus_balance_entry_requests.kind = 'bonus'
      WHERE ERScope.id = ER.id
    SQL
  end
end
