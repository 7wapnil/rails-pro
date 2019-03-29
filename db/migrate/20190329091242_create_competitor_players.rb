class CreateCompetitorPlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :competitor_players, id: false do |t|
      t.references :competitor, foreign_key: true
      t.references :player, foreign_key: true
    end
  end
end
