# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class DataSourceHandler < MixDataFeed::BaseHandler
      DATA_SOURCE_FILTER = %w[arcane-casino arcane-live-casino].freeze

      private

      def handle_update_message
        return if DATA_SOURCE_FILTER.exclude?(data_source_name)

        @categories = processed_categories

        process_play_items
      end

      def data_source_name
        data['id'].downcase
      end

      def processed_categories
        raw_categories.map(&method(:process_category!))
      end

      def process_category!(category_data)
        EveryMatrix::Category
          .create_with(label: category_data['id'].underscore.humanize.titleize)
          .find_or_create_by(context: category_data['id'])
      end

      def process_play_items
        play_items_data.each do |key, raw_play_items|
          PlayItemCategories::ProcessPlayItemsService.call(
            category_name: key,
            raw_play_items: raw_play_items,
            categories: @categories,
            data_source_name: data_source_name
          )
        end
      end

      def play_items_data
        return @play_items_data unless @play_items_data.blank?

        @play_items_data = {}

        raw_categories.each.with_index do |data, index|
          @play_items_data[raw_categories[index]['id']] =
            dig_items(data['items'])
        end

        @play_items_data
      end

      def raw_categories
        @raw_categories ||= data['categories']
      end

      def dig_items(items)
        items.flat_map do |item|
          item['isGroup'] ? dig_items(item['items']) : item
        end
      end
    end
  end
end
