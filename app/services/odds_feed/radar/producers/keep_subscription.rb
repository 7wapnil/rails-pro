# frozen_string_literal: true

module OddsFeed
  module Radar
    module Producers
      class KeepSubscription < ApplicationService
        include Producers::Heartbeatable
        include Producers::Recoverable

        def initialize(producer:, requested_at:)
          @producer = producer
          @requested_at = requested_at
        end

        def call
          return accept_message_with_recovery if previous_heartbeat_expired?

          accept_message
        end

        private

        attr_reader :producer, :requested_at
      end
    end
  end
end
