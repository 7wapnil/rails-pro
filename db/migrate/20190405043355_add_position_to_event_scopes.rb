class AddPositionToEventScopes < ActiveRecord::Migration[5.2]
  def change
    add_column :event_scopes, :position, :integer, null: false, default: 9999
    add_index  :event_scopes, :position
  end
end
