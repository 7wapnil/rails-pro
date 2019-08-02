# frozen_string_literal: true

module OddsFeed
  module Radar
    class EventStartTimeUpdateService < ApplicationService
      include JobLogger

      TIMESTAMP_SIZE = 10

      def initialize(event:, payload_time:)
        @event = event
        @payload_time = payload_time
      end

      def call
        # TODO: Remove API call if error doesn't raise at all
        compare_time

        event.update!(start_at: api_start_time)
      end

      private

      attr_reader :event, :payload_time

      def compare_time
        return if api_start_time.to_datetime == fixture_start_time

        log_job_message(:warn, message: 'Start time mismatch',
                               api_start_time: api_start_time,
                               fixture_start_time: fixture_start_time)
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
          DateTime.strptime(payload_time.first(TIMESTAMP_SIZE), '%s')
      end
    end
  end
end
