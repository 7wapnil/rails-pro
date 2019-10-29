# frozen_string_literal: true

class CreateTableDetails < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :every_matrix_table_details do |t|
      t.boolean :is_vip_table, default: false
      t.boolean :is_open, default: false
      t.boolean :is_seats_unlimited, default: false
      t.boolean :is_bet_behind_available, default: false

      t.decimal :max_limit, precision: 9, scale: 4, default: 0
      t.decimal :min_limit, precision: 9, scale: 4, default: 0

      t.string :play_item_id, null: false, index: true

      t.timestamps
    end

    add_foreign_key :every_matrix_table_details,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: 'external_id'
  end
end
