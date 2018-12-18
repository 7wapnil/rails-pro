module OddsFeed
  module Radar
    class RadarMessageHandler < MessageHandler
      include JobLogger

      def api_client
        @api_client ||= Client.new
      end
    end
  end
end
