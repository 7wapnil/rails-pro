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

          unless message.subscribed?
            return product.unsubscribe!(with_recovery: true)
          end

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
