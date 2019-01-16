class AddIntialStateToEntryRequestStatuses < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:entry_requests, :status, 'initial')
  end
end
