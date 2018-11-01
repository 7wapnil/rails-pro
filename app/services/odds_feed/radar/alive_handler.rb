module OddsFeed
  module Radar
    class AliveHandler < RadarMessageHandler
      def handle
        message = ::Radar::AliveMessage.from_hash(alive_message_data)
        message.process!
      end

      private

      def alive_message_data
        @payload['alive']
      end
    end
  end
end
