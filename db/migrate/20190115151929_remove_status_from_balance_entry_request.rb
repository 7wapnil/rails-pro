class RemoveStatusFromBalanceEntryRequest < ActiveRecord::Migration[5.2]
  def change
    remove_column :balance_entry_requests, :status
  end
end
