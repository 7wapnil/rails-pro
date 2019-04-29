class AddUniqueIndexToEventCompetitors < ActiveRecord::Migration[5.2]
  def up
    delete_duplicates

    add_index :event_competitors, %i[event_id competitor_id], unique: true
  end

  def down
    remove_index :event_competitors, %i[event_id competitor_id]
  end

  private

  # Avoid non-unique errors
  def delete_duplicates
    EventCompetitor.delete_all
  end
end
