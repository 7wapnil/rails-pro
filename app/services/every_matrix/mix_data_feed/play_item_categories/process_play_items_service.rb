# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    module PlayItemCategories
      class ProcessPlayItemsService < ApplicationService
        GAMES_DATA_SOURCE = [
          Category::CASINO_DESKTOP, Category::CASINO_MOBILE
        ].freeze

        def initialize(params)
          @category_name = params[:category_name]
          @raw_play_items = params[:raw_play_items]
          @categories = params[:categories]
          @data_source = params[:data_source_name]
        end

        def call
          clear_unknown_play_items!

          return unless requires_update?

          destroy_outdated_play_items!
          create_or_update_play_items!
        end

        private

        attr_reader :category_name, :raw_play_items, :categories,
                    :data_source, :new_items_data

        def clear_unknown_play_items!
          ids = raw_play_items.map(&method(:fetch_ids)) & play_item_ids

          @new_items_data =
            raw_play_items.select { |data| ids.include?(data['id']) }
        end

        def play_item_ids
          @play_item_ids ||= EveryMatrix::PlayItem
                             .where(type: play_item_type.name)
                             .pluck(:external_id)
        end

        def play_item_type
          return EveryMatrix::Game if GAMES_DATA_SOURCE.include?(data_source)

          EveryMatrix::Table
        end

        def requires_update?
          persisted_items_ids != new_items_data.map(&method(:fetch_ids))
        end

        def fetch_ids(data)
          data['id']
        end

        def persisted_items_ids
          @persisted_items_ids ||= EveryMatrix::PlayItemCategory
                                   .where(category: category)
                                   .order(:position)
                                   .pluck(:play_item_id)
        end

        def category
          @category ||= categories.find do |record|
            record.context == category_name
          end
        end

        def destroy_outdated_play_items!
          PlayItemCategories::DeleteService
            .call(persisted_items_ids, new_items_data, category)
        end

        def create_or_update_play_items!
          PlayItemCategories::UpdateOrCreateService
            .call(new_items_data, category)
        end
      end
    end
  end
end
