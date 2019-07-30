# frozen_string_literal: true

module OddsFeed
  module Radar
    class EventStartTimeUpdateService < ApplicationService
      def initialize(event:, payload_time:)
        @event = event
        @payload_time = payload_time
      end

      def call
        compare_time
        event.update!(start_at: api_start_time)
      end

      private

      attr_reader :event, :payload_time

      def compare_time
        return if api_start_time.to_datetime == fixture_start_time

        Rails.logger.warn(
          message: "API: #{api_start_time} != Fixture: #{fixture_start_time}",
          event_id: event.id
        )
      end

      def api_start_time
        @api_start_time ||= fixture['start_time']
      end

      def fixture
        Client.instance.event(event.external_id).payload
      end

      def fixture_start_time
        return unless payload_time

        @fixture_start_time ||=
          DateTime.strptime(payload_time.first(10), '%s')
      end
    end
  end
end
