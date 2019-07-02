class DropWithdrawalRequests < ActiveRecord::Migration[5.2]
  def up
    drop_table :withdrawal_requests
  end

  def down
    create_table 'withdrawal_requests', force: :cascade do |t|
      t.string 'status', default: 'pending'
      t.jsonb 'payment_details'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.bigint 'actioned_by_id'

      t.index ['actioned_by_id'],
              name: 'index_withdrawal_requests_on_actioned_by_id'
    end

    add_foreign_key 'withdrawal_requests', 'users', column: 'actioned_by_id'
  end
end
