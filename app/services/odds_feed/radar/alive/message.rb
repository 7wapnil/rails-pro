# frozen_string_literal: true

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
          return true unless product.last_successful_subscribed_at

          received_at < product.last_successful_subscribed_at
        end

        def subscribed?
          @subscribed == '1'
        end

        def received_at
          Time.zone.strptime(@timestamp.to_s, '%Q')
        end
      end
    end
  end
end
