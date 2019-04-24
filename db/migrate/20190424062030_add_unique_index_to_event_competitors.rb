class AddUniqueIndexToEventCompetitors < ActiveRecord::Migration[5.2]
  def up
    delete_duplicates

    add_index :event_competitors, %i[event_id competitor_id], unique: true
  end

  def down
    remove_index :event_competitors, %i[event_id competitor_id]
  end

  private

  def delete_duplicates
    sql = <<~SQL
DELETE FROM event_competitors a USING event_competitors b
WHERE
    a.event_id < b.event_id
    AND a.competitor_id = b.competitor_id
SQL

    execute(sql)
  end
end
