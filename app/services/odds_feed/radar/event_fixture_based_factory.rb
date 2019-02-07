module OddsFeed
  module Radar
    class EventFixtureBasedFactory
      BOOKED_FIXTURE_STATUS = 'booked'.freeze

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
          start_at: start_at,
          name: event_name,
          description: event_name,
          traded_live: event_traded_live?,
          payload: payload
        }
      end

      def start_at
        start_at_field = fixture['start_time'] || fixture['scheduled']
        start_at_field.to_time
      end

      def payload
        {
          competitors: fixture['competitors'],
          liveodds: fixture['liveodds']
        }
      end

      def event_name
        competitors = fixture['competitors']['competitor']
        raise NotImplementedError unless competitors.length == 2

        competitor1 = competitors[0]
        competitor2 = competitors[1]
        "#{competitor1['name']} VS #{competitor2['name']}"
      end

      def event_traded_live?
        fixture['liveodds'] == BOOKED_FIXTURE_STATUS
      end
    end
  end
end
