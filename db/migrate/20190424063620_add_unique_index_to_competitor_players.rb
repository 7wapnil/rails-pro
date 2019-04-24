class AddUniqueIndexToCompetitorPlayers < ActiveRecord::Migration[5.2]
  def up
    delete_duplicates

    add_index :competitor_players, %i[competitor_id player_id], unique: true
  end

  def down
    remove_index :competitor_players, %i[competitor_id player_id]
  end

  private

  def delete_duplicates
    sql = <<~SQL
DELETE FROM competitor_players a USING competitor_players b
WHERE
    a.competitor_id < b.competitor_id
    AND a.player_id = b.player_id
    SQL

    execute(sql)
  end
end
