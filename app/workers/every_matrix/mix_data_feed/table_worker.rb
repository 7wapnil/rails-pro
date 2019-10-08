# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class TableWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        TableHandler
      end
    end
  end
end
