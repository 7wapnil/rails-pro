# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class DataSourceHandler < MixDataFeed::BaseHandler
      DATA_SOURCE_FILTER = [
        Category::CASINO_DESKTOP,
        Category::LIVE_CASINO_DESKTOP,
        Category::CASINO_MOBILE,
        Category::LIVE_CASINO_MOBILE
      ].freeze

      DESKTOP_DATA_SOURCES = [
        Category::CASINO_DESKTOP, Category::LIVE_CASINO_DESKTOP
      ].freeze

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
        context = name_with_platform(category_data['id'])
        label = category_data['id'].underscore.humanize.titleize

        EveryMatrix::Category
          .create_with(label: label, platform_type: platform_type)
          .find_or_create_by(context: context)
      end

      def name_with_platform(context)
        "#{context}-#{platform_type}"
      end

      def platform_type
        return Category::DESKTOP if desktop_data_source?

        Category::MOBILE
      end

      def desktop_data_source?
        DESKTOP_DATA_SOURCES.include?(data_source_name)
      end

      def process_play_items
        play_items_data.each do |key, raw_play_items|
          PlayItemCategories::ProcessPlayItemsService.call(
            category_name: name_with_platform(key),
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
