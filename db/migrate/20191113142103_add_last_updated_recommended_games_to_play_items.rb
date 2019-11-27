class AddLastUpdatedRecommendedGamesToPlayItems < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_play_items,
               :last_updated_recommended_games_at,
               :datetime
  end
end
