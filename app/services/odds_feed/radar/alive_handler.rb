module OddsFeed
  module Radar
    class AliveHandler < RadarMessageHandler
      def handle
        message = ::Radar::AliveMessage.from_hash(alive_message_data)
        message.save

        message.recover! unless message.subscribed?
      end

      private

      def alive_message_data
        @payload['alive']
      end
    end
  end
end
