# frozen_string_literal: true

class AddIndexForPlayItemSlug < ActiveRecord::Migration[5.2]
  def change
    add_index :every_matrix_play_items, :slug
  end
end
