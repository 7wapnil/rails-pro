module OddsFeed
  module Radar
    module Alive
      class Message
        attr_reader :timestamp, :product_id

        def initialize(payload)
          @timestamp = payload['timestamp'].to_i
          @product_id = payload['product'].to_i
          @subscribed = payload['subscribed']
        end

        def product
          @product ||= OddsFeed::Radar::Product.new(product_id)
        end

        def datetime
          Time.zone.at(timestamp).to_datetime
        end

        def subscribed?
          @subscribed == '1'
        end
      end
    end
  end
end
