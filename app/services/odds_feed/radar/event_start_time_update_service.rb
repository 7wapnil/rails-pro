# frozen_string_literal: true

module OddsFeed
  module Radar
    class EventStartTimeUpdateService < ApplicationService
      def initialize(event:)
        @event = event
      end

      def call
        event.update!(start_at: start_time)
      end

      private

      attr_reader :event

      def start_time
        fixture['start_time']
      end

      def fixture
        Client.instance.event(event.external_id).payload
      end
    end
  end
end
