# frozen_string_literal: true

class AddIndexForPlayItemGameCode < ActiveRecord::Migration[5.2]
  def change
    add_index :every_matrix_play_items, :game_code
  end
end
