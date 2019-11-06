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

        process_categories
        process_play_items
      end

      def data_source_name
        data['id'].downcase
      end

      def process_categories
        categories.each do |category_data|
          next if category_exist?(name_with_platform(category_data['id']))

          EveryMatrix::Category.create(
            name: name_with_platform(category_data['id']),
            label: category_data['id'].underscore.humanize.titleize,
            platform_type: platform_type
          )
        end
      end

      def category_exist?(category_name)
        EveryMatrix::Category.exists?(name: category_name)
      end

      def name_with_platform(name)
        "#{name}-#{platform_type}"
      end

      def platform_type
        return Category::DESKTOP if desktop_data_source?

        Category::MOBILE
      end

      def desktop_data_source?
        DESKTOP_DATA_SOURCES.include?(data_source_name)
      end

      # TODO: refactor the way we handle categories to improve performance

      def process_play_items
        play_items_data.each do |key, value|
          category =
            EveryMatrix::Category.find_by(name: name_with_platform(key))
          category.play_item_categories.destroy_all

          value.each_with_index do |data, index|
            play_item =
              EveryMatrix::PlayItem.find_by(external_id: data['id'].to_s)

            create_play_item_category(play_item, category)
            update_play_item_position(play_item, index)
            trigger_play_item_update(play_item, category.name)
          end
        end
      end

      def play_items_data
        return @play_items_data unless @play_items_data.blank?

        @play_items_data = {}

        categories.map.with_index do |data, index|
          @play_items_data[categories[index]['id']] =
            dig_items(data['items']).flatten
        end

        @play_items_data
      end

      def dig_items(items)
        items.map do |item|
          item['isGroup'] ? dig_items(item['items']) : item
        end
      end

      def categories
        @categories ||= data['categories']
      end

      def create_play_item_category(play_item, category)
        EveryMatrix::PlayItemCategory.create(
          play_item: play_item,
          category: category
        )
      end

      def update_play_item_position(play_item, index)
        play_item&.update!(position: index)
      end

      def trigger_play_item_update(play_item, context)
        WebSocket::Client
          .instance
          .trigger_play_items_update(play_item, context)
      end
    end
  end
end
