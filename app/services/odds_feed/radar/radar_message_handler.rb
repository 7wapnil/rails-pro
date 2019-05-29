# frozen_string_literal: true

module OddsFeed
  module Radar
    class RadarMessageHandler < MessageHandler
      include JobLogger

      def api_client
        @api_client ||= ::OddsFeed::Radar::Client.instance
      end
    end
  end
end
