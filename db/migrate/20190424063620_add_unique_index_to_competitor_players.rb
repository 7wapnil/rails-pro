class AddUniqueIndexToCompetitorPlayers < ActiveRecord::Migration[5.2]
  def up
    delete_duplicates

    add_index :competitor_players, %i[competitor_id player_id], unique: true
  end

  def down
    remove_index :competitor_players, %i[competitor_id player_id]
  end

  private

  # Avoid non-unique errors
  def delete_duplicates
    CompetitorPlayer.delete_all
  end
end
