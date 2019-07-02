class CreateCustomerTransactions < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :customer_transactions do |t|
      t.string :type
      t.string :status
      t.string :external_id
      t.bigint 'actioned_by_id'
      t.bigint 'customer_bonus_id'
      t.jsonb :details
      t.datetime :finalized_at

      t.timestamps

      t.index ['actioned_by_id'],
              name: 'index_customer_transactions_on_actioned_by_id'

      t.index ['customer_bonus_id'],
              name: 'index_customer_transactions_on_customer_bonus_id'
    end

    add_foreign_key 'customer_transactions', 'customer_bonuses'
    add_foreign_key 'customer_transactions', 'users', column: 'actioned_by_id'
  end
end
