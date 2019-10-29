# frozen_string_literal: true

class AddPositionToPlayItem < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_play_items, :position, :integer
  end
end
