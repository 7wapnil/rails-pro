# frozen_string_literal: true

class CreateEveryMatrixPlayItem < ActiveRecord::Migration[5.2]
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def change
    create_table :every_matrix_play_items, id: false do |t|
      t.primary_key :external_id, :string
      t.string :type, null: false, index: true

      t.string :slug
      t.decimal :theoretical_payout, precision: 14, scale: 2, default: 0
      t.decimal :third_party_fee, precision: 14, scale: 2, default: 0
      t.decimal :fpp, precision: 14, scale: 2, default: 0
      t.text :restricted_territories, array: true, default: []
      t.text :languages, array: true, default: []
      t.text :currencies, array: true, default: []
      t.string :terminal, array: true, default: []
      t.string :tags, array: true, default: []
      t.string :url
      t.datetime :external_created_at
      t.datetime :external_updated_at

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

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
