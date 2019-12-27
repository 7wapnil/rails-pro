# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class JackpotWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        JackpotHandler
      end
    end
  end
end
