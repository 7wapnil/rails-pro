class AddEntryRequestOriginColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :entry_requests, :origin, :integer
  end
end
