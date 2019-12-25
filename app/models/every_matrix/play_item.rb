# frozen_string_literal: true

module EveryMatrix
  class PlayItem < ApplicationRecord
    self.table_name = :every_matrix_play_items

    MOBILE_PLATFORMS = %w[Android iPad iPhone].freeze
    DESKTOP_PLATFORM = %w[PC].freeze
    JOINER = ' OR '
    CASINO = 'casino'
    LIVE_CASINO = 'live-casino'

    PLATFORM_TYPES = {
      desktop: DESKTOP = 'desktop',
      mobile: MOBILE = 'mobile'
    }.freeze

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

    class << self
      def reject_country(country)
        return all if country.blank?

        where.not(':country = ANY(restricted_territories)', country: country)
      end

      def mobile
        where(MOBILE_PLATFORMS.map(&method(:base_query)).join(JOINER))
      end

      def desktop
        where(DESKTOP_PLATFORM.map(&method(:base_query)).join(JOINER))
      end

      private

      def base_query(platform)
        "'#{platform}' = ANY(terminal)"
      end
    end
  end
end
