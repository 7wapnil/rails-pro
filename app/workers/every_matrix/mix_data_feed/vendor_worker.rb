# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class VendorWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        VendorHandler
      end
    end
  end
end
