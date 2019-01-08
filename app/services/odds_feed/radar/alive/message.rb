module OddsFeed
  module Radar
    module Alive
      class Message
        attr_reader :timestamp

        def initialize(payload)
          @timestamp = payload['timestamp'].to_i
          @product_id = payload['product'].to_i
          @subscribed = payload['subscribed']
        end

        def product
          @product ||= ::Radar::Producer.find(@product_id)
        end

        def expired?
          received_at < product.last_successful_subscribed_at
        end

        def subscribed?
          @subscribed == '1'
        end

        private

        def received_at
          Time.zone.at(timestamp)
        end
      end
    end
  end
end
