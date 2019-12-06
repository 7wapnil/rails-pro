# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    module PlayItemCategories
      class DeleteService < ApplicationService
        def initialize(old_item_ids, new_item_data, category)
          @old_item_ids = old_item_ids
          @new_item_data = new_item_data
          @category = category
        end

        def call
          return if ids_difference.empty?

          EveryMatrix::PlayItemCategory
            .where(play_item_id: ids_difference, category: category)
            .destroy_all
        end

        private

        attr_reader :old_item_ids, :new_item_data, :category

        def ids_difference
          @ids_difference ||=
            old_item_ids - new_item_data.map(&method(:fetch_ids))
        end

        def fetch_ids(data)
          data['id']
        end
      end
    end
  end
end
