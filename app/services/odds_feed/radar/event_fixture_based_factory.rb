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
          start_at: replay_mode? ? patched_start_time : start_at,
          name: event_name,
          description: event_name,
          traded_live: event_traded_live?,
          liveodds: liveodds,
          status: fixture['status']
        }
      end

      def replay_mode?
        ENV['RADAR_MQ_IS_REPLAY'] == 'true'
      end

      def start_at
        start_at_field = fixture['start_time'] || fixture['scheduled']
        start_at_field.to_time
      end

      def liveodds
        fixture['liveodds']
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
