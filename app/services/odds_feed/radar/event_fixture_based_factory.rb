# frozen_string_literal: true

module OddsFeed
  module Radar
    class EventFixtureBasedFactory
      BOOKED_FIXTURE_STATUS = 'booked'

      attr_reader :fixture

      def initialize(fixture:)
        @fixture = fixture
      end

      def event
        Event.new(event_attributes)
      end

      private

      def event_attributes
        {
          external_id: fixture['id'],
          start_at: expected_start_time,
          twitch_start_time: expected_start_time,
          twitch_end_time: expected_finish_time,
          name: event_name,
          traded_live: event_traded_live?,
          liveodds: liveodds,
          status: EventStatusConverter.call(fixture['status'])
        }
      end

      def expected_start_time
        @expected_start_time ||= replay_mode? ? patched_start_time : start_at
      end

      def expected_finish_time
        expected_start_time + Event::TWITCH_END_TIME_DELAY
      end

      def event_name
        competitors = fixture['competitors']['competitor']
        raise NotImplementedError unless competitors.length == 2

        competitor1 = competitors[0]
        competitor2 = competitors[1]
        "#{competitor1['name']} VS #{competitor2['name']}"
      end

      def event_traded_live?
        liveodds == BOOKED_FIXTURE_STATUS
      end

      def liveodds
        fixture['liveodds']
      end

      def replay_mode?
        ENV['RADAR_MQ_IS_REPLAY'] == 'true'
      end

      def start_at
        start_at_field = fixture['start_time'] || fixture['scheduled']
        start_at_field.to_time
      end

      def patched_start_time
        start_at_field = fixture['start_time'] || fixture['scheduled']
        original_start_time = DateTime.parse(start_at_field)
        today = Date.tomorrow

        original_start_time.change(
          year: today.year,
          month: today.month,
          day: today.day
        )
      end
    end
  end
end
