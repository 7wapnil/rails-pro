class UpdateExternalIdIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :titles, :external_id
    remove_index :events, :external_id
    remove_index :event_scopes, :external_id
    remove_index :markets, :external_id
    remove_index :odds, :external_id

    add_index :titles, :external_id, unique: true
    add_index :events, :external_id, unique: true
    add_index :event_scopes, :external_id, unique: true
    add_index :markets, :external_id, unique: true
    add_index :odds, :external_id, unique: true
  end
end
