# frozen_string_literal: true

module EveryMatrix
  class OverviewLoader < BatchLoader
    LIMIT_PER_CATEGORY = 10

    def initialize(model, country_code = '')
      @country_code = country_code
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

    attr_reader :country_code

    def scope
      EveryMatrix::PlayItem
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
        SELECT id, external_id
        FROM every_matrix_categories, LATERAL (
          SELECT every_matrix_play_items.external_id
          FROM every_matrix_play_items
          JOIN every_matrix_play_item_categories
          ON every_matrix_play_item_categories.play_item_id = every_matrix_play_items.external_id
          WHERE every_matrix_categories.id = every_matrix_play_item_categories.category_id
          AND NOT '#{country_code}' = ANY(every_matrix_play_items.restricted_territories)
          ORDER BY every_matrix_play_items.position ASC
          LIMIT #{LIMIT_PER_CATEGORY}) play_items
        WHERE every_matrix_categories.id IN (#{category_ids.join(', ').presence || 'NULL'})
      SQL
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
        @records.select { |play_item| play_item_ids.include?(play_item.id) }

      fulfill(category, play_items)
    end
  end
end
