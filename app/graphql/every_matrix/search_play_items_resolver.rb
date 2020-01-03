# frozen_string_literal: true

module EveryMatrix
  class SearchPlayItemsResolver < ApplicationService
    MAX_LIMIT = 35
    CASINO_CONTEXT = 'casino'
    LIVE_CASINO_CONTEXT = 'live_casino'

    def initialize(query:, country:, device:, context:)
      @query = query
      @country = country
      @device = device
      @model = fetch_model(context)
    end

    def call
      model.joins(:content_provider)
           .reject_country(country)
           .where(name_includes_search_query, query: "%#{query}%")
           .public_send(device)
           .group(:external_id)
           .order(sort_by_name)
    end

    private

    attr_reader :query, :country, :device, :model

    def fetch_model(context)
      case context
      when CASINO_CONTEXT then EveryMatrix::Game
      when LIVE_CASINO_CONTEXT then EveryMatrix::Table
      else EveryMatrix::PlayItem
      end
    end

    def name_includes_search_query
      <<~SQL
        every_matrix_play_items.name ILIKE :query OR
        every_matrix_play_items.short_name ILIKE :query OR
        every_matrix_content_providers.name ILIKE :query
      SQL
    end

    def sort_by_name
      <<~SQL
        CASE
          WHEN every_matrix_play_items.name IS NOT NULL AND
               every_matrix_play_items.name ILIKE '#{@query}%' OR
               every_matrix_play_items.short_name ILIKE '#{@query}%'
            THEN 0
          ELSE 1
        END
      SQL
    end
  end
end
