# frozen_string_literal: true

module OddsFeed
  module Radar
    module Producers
      module Heartbeatable
        DEFAULT_HEARTBEAT_INTERVAL_LIMIT = 15.seconds
        HEARTBEAT_INTERVAL_LIMITS = {
          ::Radar::Producer::LIVE_PROVIDER_CODE => 15.seconds,
          ::Radar::Producer::PREMATCH_PROVIDER_CODE => 5.minutes
        }.freeze

        delegate :last_subscribed_at, to: :producer

        protected

        def producer
          raise NotImplementedError, 'Method #producer has to be implemented'
        end

        def previous_heartbeat_expired?
          last_subscribed_at.present? &&
            last_subscribed_at < heartbeat_limit.ago
        end

        def heartbeat_limit
          HEARTBEAT_INTERVAL_LIMITS
            .fetch(producer.code, DEFAULT_HEARTBEAT_INTERVAL_LIMIT)
        end
      end
    end
  end
end
