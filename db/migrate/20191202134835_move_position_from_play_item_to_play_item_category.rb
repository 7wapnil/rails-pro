# frozen_string_literal: true

class MovePositionFromPlayItemToPlayItemCategory < ActiveRecord::Migration[5.2]
  def change
    remove_column :every_matrix_play_items, :position

    add_column :every_matrix_play_item_categories, :position, :integer
  end
end
