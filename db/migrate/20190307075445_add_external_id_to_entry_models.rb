class AddExternalIdToEntryModels < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :external_id, :string
    add_column :entry_requests, :external_id, :string
  end
end
