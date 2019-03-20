class CreateWithdrawalRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :withdrawal_requests do |t|
      t.string :status, default: 'pending'
      t.jsonb :payment_details

      t.timestamps
    end
  end
end
