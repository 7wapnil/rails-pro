class AddExternalIdColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :titles, :external_id, :string, null: true
    add_column :events, :external_id, :string, null: true
    add_column :markets, :external_id, :string, null: true
    add_column :event_scopes, :external_id, :string, null: true

    add_index :titles, :external_id
    add_index :events, :external_id
    add_index :markets, :external_id
    add_index :event_scopes, :external_id
  end
end
