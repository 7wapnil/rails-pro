class CreateEveryMatrixRecommendedGamesRelationships < ActiveRecord::Migration[5.2] # rubocop:disable Metrics/LineLength
  def change # rubocop:disable Metrics/MethodLength
    create_table :every_matrix_recommended_games_relationships do |t|
      t.references :original_game,
                   foreign_key: {
                     to_table: :every_matrix_play_items,
                     primary_key: :external_id
                   },
                   type: :string,
                   index: {
                     name: 'index_original_game_on_play_item'
                   }

      t.references :recommended_game,
                   foreign_key: {
                     to_table: :every_matrix_play_items,
                     primary_key: :external_id
                   },
                   type: :string,
                   index: {
                     name: 'index_recommended_game_on_play_item'
                   }

      t.timestamps
    end
  end
end
