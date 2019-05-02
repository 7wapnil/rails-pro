module EventsManager
  module Entities
    class Event < BaseEntity
      MATCH_TYPE_REGEXP = /:match:/
      BOOKED_FIXTURE_STATUS = 'booked'.freeze

      def self.type_match?(id)
        id.to_s.match?(MATCH_TYPE_REGEXP)
      end

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
        liveodds == BOOKED_FIXTURE_STATUS
      end

      def liveodds
        attribute(fixture, 'liveodds')
      end

      def competitors
        competitors = attribute(fixture, 'competitors', 'competitor')
        @competitors ||= competitors.map do |data|
          SimpleEntity.new(data)
        end
      end

      def sport
        @sport ||= create_entity(
          attribute!(fixture, 'tournament', 'sport')
        )
      end

      def category
        @category ||= create_entity(
          attribute(fixture, 'tournament', 'category')
        )
      end

      def tournament
        @tournament ||= create_entity(attribute!(fixture, 'tournament'))
      end

      def season
        @season ||= create_entity(attribute(fixture, 'season'))
      end

      private

      def create_entity(data)
        return nil unless data

        SimpleEntity.new(data)
      end

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
    end
  end
end
