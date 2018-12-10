module OddsFeed
  module Radar
    class EventAdapter < BaseAdapter
      def result
        @event = Event.new(event_attributes)
        attach_title!
        find_or_create_scopes!

        # @todo Archivation is disabled temporary and must be
        # re-build with other ticket
        # @see https://trello.com/c/VbAQP0JZ/216-archive-events-recurrently-on-cleanup
        # archive_event_and_scopes!

        @event
      end

      private

      def fixture
        @payload
      end

      def title_fixture
        unless tournament_fixture.present?
          raise OddsFeed::InvalidMessageError, 'Tournament fixture not found'
        end

        tournament_fixture['sport']
      end

      def tournament_fixture
        unless fixture['tournament'].present?
          raise OddsFeed::InvalidMessageError,
                'Tournament fixture must be present'
        end
        fixture['tournament']
      end

      def season_fixture
        fixture['season']
      end

      def country_fixture
        tournament_fixture['category']
      end

      def event_attributes
        start_at_field = fixture['start_time'] || fixture['scheduled']

        { external_id: fixture['id'],
          start_at: start_at_field.to_time,
          name: event_name,
          description: event_name,
          payload: { competitors: fixture['competitors'] } }
      end

      def event_name
        competitors = fixture['competitors']['competitor']
        raise NotImplementedError unless competitors.length == 2

        competitor1 = competitors[0]
        competitor2 = competitors[1]
        "#{competitor1['name']} VS #{competitor2['name']}"
      end

      def attach_title!
        Rails.logger.debug "Title data received: #{title_fixture}"
        @event.title = EventAdapter::TitleSelector.call(payload: title_fixture)
      end

      def find_or_create_scopes!
        find_or_create_tournament!
        find_or_create_season!
        find_or_create_country!
      end

      def find_or_create_tournament!
        data = tournament_fixture
        Rails.logger.debug "Tournament data received: #{data}"
        find_or_create_scope!(external_id: data['id'],
                              kind: :tournament,
                              name: tournament_fixture['name'],
                              title: @event.title)
      end

      def find_or_create_season!
        Rails.logger.debug "Season data received: #{season_fixture}"

        unless season_fixture
          Rails.logger.info 'Season fixture is missing in payload, exiting'
          return
        end

        find_or_create_scope!(external_id: season_fixture['id'],
                              name: season_fixture['name'],
                              kind: :season,
                              title: @event.title)
      end

      def find_or_create_country!
        Rails.logger.debug "Country data received: #{country_fixture}"

        unless country_fixture
          Rails.logger.info 'Country fixture is missing in payload, exiting'
          return
        end

        find_or_create_scope!(external_id: country_fixture['id'],
                              name: country_fixture['name'],
                              kind: :country,
                              title: @event.title)
      end

      def find_or_create_scope!(attributes)
        scope = EventScope.find_or_create_by!(attributes) do |obj|
          log_msg = <<-MESSAGE
            Create new scope kind '#{obj.kind}' \
            with external ID '#{obj.external_id}' \
            and name '#{obj.name}'
          MESSAGE
          Rails.logger.info log_msg.squish
        end
        @event.event_scopes << scope
      end

      def archive_event_and_scopes!
        EventArchive::Service.call(event: @event)
      end
    end
  end
end
