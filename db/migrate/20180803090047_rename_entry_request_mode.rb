class RenameEntryRequestMode < ActiveRecord::Migration[5.2]
  def change
    rename_column :entry_requests, :origin, :mode
  end
end
