# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class GameHandler < MixDataFeed::PlayItemHandler
      protected

      def assign_details!(game)
        Games::DetailsGenerator.call(data: data, game: game)
      end

      def play_item_type
        EveryMatrix::Game.name
      end
    end
  end
end
