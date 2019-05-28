class DropDepositRequests < ActiveRecord::Migration[5.2]
  def up
    drop_table :deposit_requests
  end

  def down
    create_table 'deposit_requests', force: :cascade do |t|
      t.bigint 'customer_bonus_id'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false

      t.index ['customer_bonus_id'],
              name: 'index_deposit_requests_on_customer_bonus_id'
    end

    add_foreign_key 'deposit_requests', 'customer_bonuses'
  end
end
