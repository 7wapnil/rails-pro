# frozen_string_literal: true

module OddsFeed
  module Radar
    class ProducerUpdateService < ApplicationService
      PRODUCER_PRIORITY = {
        ::Radar::Producer::PREMATCH_PROVIDER_ID => 1,
        ::Radar::Producer::LIVE_PROVIDER_ID => 2
      }.freeze

      def initialize(event:, producer_id:)
        @event = event
        @producer_id = producer_id
      end

      def call
        old_priority = PRODUCER_PRIORITY[event.producer_id]
        new_priority = PRODUCER_PRIORITY[producer_id]

        return if old_priority >= new_priority

        event.assign_attributes(producer_id: producer_id)
      end

      private

      attr_accessor :event, :producer_id
    end
  end
end
