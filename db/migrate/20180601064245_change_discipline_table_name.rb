class ChangeDisciplineTableName < ActiveRecord::Migration[5.2]
  def up
    remove_index :events, :discipline_id
    remove_index :event_scopes, :discipline_id

    rename_table :disciplines, :titles
    rename_column :events, :discipline_id, :title_id
    rename_column :event_scopes, :discipline_id, :title_id

    add_index :events, :title_id
    add_index :event_scopes, :title_id
  end

  def down
    remove_index :events, :title_id
    remove_index :event_scopes, :title_id

    rename_table :titles, :disciplines
    rename_column :events, :title_id, :discipline_id
    rename_column :event_scopes, :title_id, :discipline_id

    add_index :events, :discipline_id
    add_index :event_scopes, :discipline_id
  end
end
