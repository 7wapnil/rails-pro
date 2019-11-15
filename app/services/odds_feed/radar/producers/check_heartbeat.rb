# frozen_string_literal: true

module OddsFeed
  module Radar
    module Producers
      class CheckHeartbeat < ApplicationService
        include Producers::Heartbeatable

        delegate :last_disconnected_at, to: :producer

        def initialize(producer:)
          @producer = producer
        end

        def call
          return false unless previous_heartbeat_expired?
          return false if last_disconnected_at && !producer.healthy?

          register_disconnection!
        rescue ::Radar::Producers::DisconnectedError => error
          log_producer_disconnection(error)
        end

        private

        attr_reader :producer

        def register_disconnection!
          producer.register_disconnection!(
            last_subscribed_at: last_subscribed_at
          )

          raise ::Radar::Producers::DisconnectedError
        end

        def log_producer_disconnection(error)
          Rails.logger.error(
            message: 'MTS producer is disconnected',
            producer_id: producer.id,
            error_object: error
          )
        end
      end
    end
  end
end
