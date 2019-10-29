# frozen_string_literal: true

class CreateGameDetails < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :every_matrix_game_details do |t|
      t.string :help_url
      t.decimal :top_prize, precision: 14, scale: 2
      t.decimal :min_hit_frequency, precision: 9, scale: 4, default: 0
      t.decimal :max_hit_frequency, precision: 9, scale: 4, default: 0
      t.boolean :free_spin_supported, default: false
      t.boolean :free_spin_bonus_supported, default: false
      t.boolean :launch_game_in_html_5, default: false

      t.string :play_item_id, null: false, index: true

      t.timestamps
    end

    add_foreign_key :every_matrix_game_details,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: 'external_id'
  end
end
