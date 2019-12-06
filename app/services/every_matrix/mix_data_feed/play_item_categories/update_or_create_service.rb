# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    module PlayItemCategories
      class UpdateOrCreateService < ApplicationService
        def initialize(new_play_items, category)
          @new_play_items = new_play_items
          @category = category
        end

        def call
          EveryMatrix::PlayItemCategory
            .create_or_update_on_duplicate(play_item_categories)
        end

        private

        attr_reader :new_play_items, :category

        def play_item_categories
          new_play_items.map.with_index do |data, index|
            {
              play_item_id: data['id'],
              category_id: category.id,
              position: index
            }
          end
        end
      end
    end
  end
end
