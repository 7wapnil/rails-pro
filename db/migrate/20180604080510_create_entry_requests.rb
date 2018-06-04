class CreateEntryRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :entry_requests do |t|
      t.integer :status, default: 0
      t.json :payload, default: '{}'
      t.json :result, null: true

      t.timestamps
    end
  end
end
