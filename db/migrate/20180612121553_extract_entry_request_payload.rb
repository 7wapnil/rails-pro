class ExtractEntryRequestPayload < ActiveRecord::Migration[5.2]
  def change
    add_column :entry_requests, :customer_id, :integer
    add_column :entry_requests, :currency_id, :integer
    add_column :entry_requests, :kind,        :integer
    add_column :entry_requests, :origin_type, :integer
    add_column :entry_requests, :origin_id,   :integer
    add_column :entry_requests, :comment,     :text
    add_column :entry_requests, :amount,      :decimal, precision: 8, scale: 2

    remove_column :entry_requests, :payload, :json

    add_foreign_key :entry_requests, :customers
    add_foreign_key :entry_requests, :currencies
  end
end
