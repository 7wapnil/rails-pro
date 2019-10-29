# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class DataSourceHandler < MixDataFeed::BaseHandler
      private

      def handle_update_message
        process_categories
        process_play_items
      end

      def process_categories
        categories.each do |category_data|
          category = EveryMatrix::Category
                     .find_or_initialize_by(name: category_data['id'])

          category.update(
            label: category_data['id'].underscore.humanize.titleize
          )
        end
      end

      def process_play_items
        play_items_data.each do |key, value|
          category = EveryMatrix::Category.find_by(name: key)
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
