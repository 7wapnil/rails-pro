# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class DataSourceWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        DataSourceHandler
      end
    end
  end
end
