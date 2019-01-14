class AddUniqueIndexToScopedEvents < ActiveRecord::Migration[5.2]
  def up
    migrate_data

    add_index :scoped_events, %i[event_id event_scope_id], unique: true
  end

  def down
    remove_index :scoped_events, %i[event_id event_scope_id]
  end

  private

  def migrate_data
    Rake::Task['migrations:scoped_events:clean_duplicates'].invoke
  end
end
