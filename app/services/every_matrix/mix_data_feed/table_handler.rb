# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class TableHandler < MixDataFeed::PlayItemHandler
      private

      def assign_details!(table)
        Tables::DetailsGenerator.call(data: data['property'], table: table)
      end

      def play_item_type
        EveryMatrix::Table.name
      end
    end
  end
end
