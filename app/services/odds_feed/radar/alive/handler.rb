# frozen_string_literal: true

module OddsFeed
  module Radar
    module Alive
      class Handler < RadarMessageHandler
        include JobLogger

        delegate :product, to: :message

        def handle
          populate_job_log_info!

          log_procedure
          return false if message.expired?

          unless message.subscribed?
            return product.unsubscribe!(with_recovery: true)
          end

          product.subscribed!(subscribed_at: message.received_at)
        end

        private

        def populate_job_log_info!
          Thread.current[:producer_id] = product&.id
          Thread.current[:producer_subscription_state] = product&.subscribed?
          Thread.current[:message_subscription_state] = message.subscribed?
        end

        def log_procedure
          log_job_message(
            :debug,
            message: "Radar Producer #{product&.code} status",
            received_at: message.received_at,
            producer_id: product&.id,
            producer_subscription_state: product&.subscribed?,
            message_subscription_state: message.subscribed?,
            expired: message.expired?
          )
        end

        def message
          Message.new(payload['alive'])
        end
      end
    end
  end
end
