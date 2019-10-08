# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class RecentWinnerWorker < MixDataFeed::BaseWorker
      private

      def handler_class
        RecentWinnerHandler
      end
    end
  end
end
