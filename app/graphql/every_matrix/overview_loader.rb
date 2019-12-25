# frozen_string_literal: true

module EveryMatrix
  class OverviewLoader < BatchLoader
    include DeviceChecker

    LIMIT_PER_CATEGORY = 20
    JOINER = ' OR '

    def initialize(model, request)
      @terminal = platform_type(request)
      @country_code = request.location.country_code.upcase
      super(model)
    end

    def perform(category_ids)
      @play_items = play_items(category_ids)
      @records = scope

      populate_categories!

      category_ids.each do |category_id|
        fulfill(category_id, []) unless fulfilled?(category_id)
      end
    end

    private

    attr_reader :terminal, :country_code

    def scope
      model
        .eager_load(:categories)
        .where(external_id: scrap_play_item_ids)
    end

    def scrap_play_item_ids
      @play_items.pluck('external_id')
    end

    def play_items(category_ids)
      ActiveRecord::Base
        .connection
        .execute(play_items_per_category_sql(category_ids))
    end

    def play_items_per_category_sql(category_ids)
      <<~SQL
        SELECT id, external_id, play_items.position
        FROM every_matrix_categories, LATERAL (
          SELECT every_matrix_play_items.external_id, every_matrix_play_item_categories.position
          FROM every_matrix_play_items
          JOIN every_matrix_play_item_categories
          ON every_matrix_play_items.external_id = every_matrix_play_item_categories.play_item_id
          WHERE every_matrix_categories.id = every_matrix_play_item_categories.category_id
          AND NOT '#{country_code}' = ANY(every_matrix_play_items.restricted_territories)
          AND (#{query_per_device})
          ORDER BY every_matrix_play_item_categories.position ASC
          LIMIT #{LIMIT_PER_CATEGORY}) play_items
        WHERE every_matrix_categories.id IN (#{category_ids.join(', ').presence || 'NULL'})
      SQL
    end

    def query_per_device
      return mobile_query if terminal == PlayItem::MOBILE

      desktop_query
    end

    def mobile_query
      PlayItem::MOBILE_PLATFORMS.map(&method(:base_query)).join(JOINER)
    end

    def base_query(platform)
      "'#{platform}' = ANY(every_matrix_play_items.terminal)"
    end

    def desktop_query
      PlayItem::DESKTOP_PLATFORM.map(&method(:base_query)).join(JOINER)
    end

    def populate_categories!
      @play_items
        .to_a
        .group_by { |row| row['id'] }
        .each { |category_id, batch| fulfill_category(batch, category_id) }
    end

    def fulfill_category(batch, category)
      play_item_ids = batch.map { |row| row['external_id'] }

      play_items =
        play_item_ids
        .map { |id| @records.find { |record| record.id == id } }

      fulfill(category, play_items)
    end
  end
end
