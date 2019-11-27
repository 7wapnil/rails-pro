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

    has_many :recommended_game_relationships,
             class_name: EveryMatrix::RecommendedGamesRelationship.name,
             foreign_key: :original_game_id
    has_many :recommended_games,
             through: :recommended_game_relationships,
             foreign_key: :recommended_game_id,
             class_name: EveryMatrix::PlayItem.name

    def self.reject_country(country)
      return all if country.blank?

      where.not(':country = ANY(restricted_territories)', country: country)
    end
  end
end
