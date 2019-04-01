module EventsManager
  module Entities
    class Event < BaseEntity
      BOOKED_FIXTURE_STATUS = 'booked'.freeze

      def id
        fixture['id']
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
        @competitors ||= fixture.dig('competitors', 'competitor').map do |data|
          SimpleEntity.new(data)
        end
      end

      def sport
        @sport ||= SimpleEntity.new(fixture.dig('tournament', 'sport'))
      end

      def category
        @category ||= SimpleEntity.new(fixture.dig('tournament', 'category'))
      end

      def tournament
        @tournament ||= SimpleEntity.new(fixture['tournament'])
      end

      def season
        @season ||= SimpleEntity.new(fixture['season'])
      end

      private

      def fixture
        @payload.dig('fixtures_fixture', 'fixture')
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
        today = Date.tomorrow

        original_start_time.change(
          year: today.year,
          month: today.month,
          day: today.day
        )
      end

      def start_time_field
        fixture['start_time'] || fixture['scheduled']
      end

      def live_odds
        fixture['liveodds']
      end
    end
  end
end
