# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
class AddCascadeForeignKeysForCasinoEntities < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :every_matrix_game_details, :every_matrix_play_items
    remove_foreign_key :every_matrix_table_details, :every_matrix_play_items
    remove_foreign_key :every_matrix_play_items, :every_matrix_vendors

    add_foreign_key :every_matrix_game_details,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: :external_id,
                    on_delete: :cascade

    add_foreign_key :every_matrix_table_details,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: :external_id,
                    on_delete: :cascade

    add_foreign_key :every_matrix_play_items,
                    :every_matrix_vendors,
                    column: :every_matrix_vendor_id,
                    on_delete: :cascade
  end

  def down
    remove_foreign_key :every_matrix_game_details, :every_matrix_play_items
    remove_foreign_key :every_matrix_table_details, :every_matrix_play_items
    remove_foreign_key :every_matrix_play_items, :every_matrix_vendors

    add_foreign_key :every_matrix_game_details,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: :external_id

    add_foreign_key :every_matrix_table_details,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: :external_id

    add_foreign_key :every_matrix_play_items,
                    :every_matrix_vendors,
                    column: :every_matrix_vendor_id
  end
end
# rubocop:enable Metrics/MethodLength
