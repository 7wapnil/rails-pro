class AddConfirmedAtToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :confirmed_at, :timestamp
  end
end
