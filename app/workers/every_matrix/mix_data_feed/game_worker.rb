# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class GameWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        GameHandler
      end
    end
  end
end
