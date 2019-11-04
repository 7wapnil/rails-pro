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

          producer.register_disconnection!(
            last_subscribed_at: last_subscribed_at
          )
        end

        private

        attr_reader :producer
      end
    end
  end
end
