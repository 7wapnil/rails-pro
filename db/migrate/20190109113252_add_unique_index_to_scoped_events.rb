class AddUniqueIndexToScopedEvents < ActiveRecord::Migration[5.2]
  def up
    add_index :scoped_events, %i[event_id event_scope_id], unique: true
  end

  def down
    remove_index :scoped_events, %i[event_id event_scope_id]
  end
end
