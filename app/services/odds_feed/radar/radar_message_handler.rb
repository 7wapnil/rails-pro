module OddsFeed
  module Radar
    class RadarMessageHandler < MessageHandler
      def api_client
        @ali_client ||= Client.new
      end
    end
  end
end
