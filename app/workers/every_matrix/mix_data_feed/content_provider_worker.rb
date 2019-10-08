# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class ContentProviderWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        ContentProviderHandler
      end
    end
  end
end
