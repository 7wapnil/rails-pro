# frozen_string_literal: true

class CreateEveryMatrixPlayItemCategory < ActiveRecord::Migration[5.2]
  def change
    create_table :every_matrix_play_item_categories do |t|
      t.string :play_item_id, null: false, index: true
      t.bigint :category_id, null: false, index: true
    end

    add_foreign_key :every_matrix_play_item_categories,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: 'external_id'
    add_foreign_key :every_matrix_play_item_categories,
                    :every_matrix_categories,
                    column: :category_id
  end
end
