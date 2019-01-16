class AddUniqueIndexOnBalanceEntryRequest < ActiveRecord::Migration[5.2]
  def change
    add_index :balance_entry_requests, %i[entry_request_id kind], unique: true
  end
end
