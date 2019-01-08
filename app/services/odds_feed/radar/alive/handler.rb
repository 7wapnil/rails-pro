module OddsFeed
  module Radar
    module Alive
      class Handler < RadarMessageHandler
        def handle
          message = Message.new(@payload['alive'])

          return false if message.expired?

          product = message.product

          return product.unsubscribe! unless message.subscribed?

          product.subscribed!
        end
      end
    end
  end
end
