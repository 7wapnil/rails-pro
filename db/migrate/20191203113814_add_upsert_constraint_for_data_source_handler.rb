# frozen_string_literal: true

class AddUpsertConstraintForDataSourceHandler < ActiveRecord::Migration[5.2]
  def change
    add_index :every_matrix_play_item_categories,
              %i[play_item_id category_id],
              unique: true,
              name: 'category_play_item_upsert'
  end
end
