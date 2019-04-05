module EventsManager
  module Entities
    class Event < BaseEntity
      BOOKED_FIXTURE_STATUS = 'booked'.freeze

      def id
        attribute!(fixture, 'id')
      end

      def name
        raise NotImplementedError unless competitors.length == 2

        competitors.map(&:name).join(' VS ')
      end

      def start_at
        replay_mode? ? patched_start_time : original_start_time
      end

      def traded_live?
        live_odds == BOOKED_FIXTURE_STATUS
      end

      def payload
        { liveodds: live_odds }
      end

      def competitors
        competitors = attribute(fixture, 'competitors', 'competitor')
        @competitors ||= competitors.map do |data|
          SimpleEntity.new(data)
        end
      end

      def sport
        @sport ||= SimpleEntity.new(
          attribute(fixture, 'tournament', 'sport')
        )
      end

      def category
        @category ||= SimpleEntity.new(
          attribute(fixture, 'tournament', 'category')
        )
      end

      def tournament
        @tournament ||= SimpleEntity.new(
          attribute(fixture, 'tournament')
        )
      end

      def season
        @season ||= SimpleEntity.new(
          attribute(fixture, 'season')
        )
      end

      private

      def fixture
        attribute!(@payload, 'fixtures_fixture', 'fixture')
      end

      def replay_mode?
        ENV['RADAR_MQ_IS_REPLAY'] == 'true'
      end

      def original_start_time
        start_time_field.to_time
      end

      def patched_start_time
        start_at_field = start_time_field
        original_start_time = DateTime.parse(start_at_field)
        today = Date.current.tomorrow

        original_start_time.change(
          year: today.year,
          month: today.month,
          day: today.day
        )
      end

      def start_time_field
        attribute(fixture, 'start_time') ||
          attribute(fixture, 'scheduled')
      end

      def live_odds
        attribute(fixture, 'liveodds')
      end
    end
  end
end
