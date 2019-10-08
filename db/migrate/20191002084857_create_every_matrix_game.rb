# frozen_string_literal: true

class CreateEveryMatrixGame < ActiveRecord::Migration[5.2]
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def change
    create_table :every_matrix_games, id: false do |t|
      t.primary_key :external_id, :string

      t.string :slug
      t.string :vendor
      t.string :content_provider
      t.text :categories, array: true, default: []
      t.decimal :theoretical_payout, precision: 14, scale: 2, default: 0
      t.decimal :third_party_fee, precision: 14, scale: 2, default: 0
      t.decimal :fpp, precision: 14, scale: 2, default: 0
      t.text :restricted_territories, array: true, default: []
      t.text :languages, array: true, default: []
      t.text :currencies, array: true, default: []
      t.string :url
      t.string :help_url
      t.datetime :external_created_at
      t.datetime :external_updated_at

      t.integer :default_coin, default: 0
      t.boolean :free_spin_supported, default: false
      t.boolean :free_spin_bonus_supported, default: false
      t.decimal :min_hit_frequency, precision: 9, scale: 4, default: 0
      t.decimal :max_hit_frequency, precision: 9, scale: 4, default: 0
      t.boolean :launch_game_in_html_5, default: false

      t.decimal :popularity_coefficient, precision: 6, scale: 4, default: 0
      t.integer :popularity_ranking, default: 0

      t.boolean :play_mode_fun, default: false
      t.boolean :play_mode_anonymity, default: false
      t.boolean :play_mode_real_money, default: false

      t.string :name
      t.string :short_name
      t.string :description
      t.string :thumbnail_url
      t.string :logo_url
      t.string :background_image_url
      t.string :small_icon_url
      t.string :medium_icon_url
      t.string :large_icon_url

      t.decimal :top_prize, precision: 14, scale: 2

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
