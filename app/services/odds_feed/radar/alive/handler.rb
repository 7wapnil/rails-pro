module OddsFeed
  module Radar
    module Alive
      class Handler < RadarMessageHandler
        include JobLogger

        delegate :product, to: :message

        def handle
          log_job_message(
            :info,
            received_at: message.received_at,
            producer_code: product&.code,
            subscription_state: message.subscribed?,
            expired: message.expired?
          )
          return false if message.expired?

          return product.unsubscribe! unless message.subscribed?

          product.subscribed!(subscribed_at: message.received_at)
        end

        private

        def log_parsed_message
          Rails.logger.send(
            :info,
            class: OddsFeed::Radar::Alive::Message.class.name,
            received_at: message.received_at,
            producer_code: message&.product&.code,
            subscription_state: message.subscribed?,
            expired: message.expired?
          )
        end

        def message
          Message.new(@payload['alive'])
        end
      end
    end
  end
end
