module OddsFeed
  module Radar
    class AliveHandler < RadarMessageHandler
      def handle
        message = ::Radar::AliveMessage.from_hash(alive_message_data)
        message.save!

        recover_message(message) unless message.subscribed?
      end

      private

      def recover_message(message)
        recover(message.product_id)
      end

      def recover(product_id)
        OddsFeed::Radar::SubscriptionRecovery
          .call(product_id: product_id)
      end

      def alive_message_data
        @payload['alive']
      end
    end
  end
end
