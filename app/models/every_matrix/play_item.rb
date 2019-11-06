# frozen_string_literal: true

module EveryMatrix
  class PlayItem < ApplicationRecord
    self.table_name = :every_matrix_play_items

    belongs_to :content_provider, foreign_key: :every_matrix_content_provider_id
    belongs_to :vendor, foreign_key: :every_matrix_vendor_id

    has_many :wallet_sessions
    has_many :play_item_categories
    has_many :categories,
             through: :play_item_categories,
             foreign_key: :every_matrix_play_item_external_id

    scope :reject_country, ->(country) {
      return if country.blank?

      where.not(':country = ANY(restricted_territories)', country: country)
    }

    def self.items_per_category(category)
      join_query = <<~SQL
        JOIN every_matrix_play_item_categories
        ON every_matrix_play_item_categories.play_item_id = every_matrix_play_items.external_id
        JOIN every_matrix_categories
        ON every_matrix_categories.id = every_matrix_play_item_categories.category_id
        AND every_matrix_categories.id = #{EveryMatrix::Category.find_by!(name: category).id}
      SQL

      joins(join_query)
    end
  end
end
