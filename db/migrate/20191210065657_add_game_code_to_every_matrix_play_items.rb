class AddGameCodeToEveryMatrixPlayItems < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_play_items, :game_code, :string
  end
end
