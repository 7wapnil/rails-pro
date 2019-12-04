class AddCancelledBonusAmountToEntryRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :entry_requests, :cancelled_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
  end
end
