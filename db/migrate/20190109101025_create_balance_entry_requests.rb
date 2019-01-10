class CreateBalanceEntryRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :balance_entry_requests do |t|
      t.references :entry_request, index: true
      t.references :balance_entry, index: true
      t.string :kind
      t.string :status, default: 'pending'
      t.decimal :amount, precision: 8, scale: 2

      t.timestamps
    end
  end
end
