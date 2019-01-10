module OddsFeed
  module Radar
    module Alive
      class Handler < RadarMessageHandler
        delegate :product, to: :message

        def handle
          return false if message.expired?

          return product.unsubscribe! unless message.subscribed?

          product.subscribed!(subscribed_at: message.received_at)
        end

        private

        def message
          Message.new(@payload['alive'])
        end
      end
    end
  end
end
