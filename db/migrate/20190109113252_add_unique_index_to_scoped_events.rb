class AddUniqueIndexToScopedEvents < ActiveRecord::Migration[5.2]
  def change
    add_index :scoped_events, %i[event_id event_scope_id], unique: true
  end
end
