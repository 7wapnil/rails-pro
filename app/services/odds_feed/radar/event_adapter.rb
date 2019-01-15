module OddsFeed
  module Radar
    class EventAdapter < BaseAdapter
      include JobLogger

      MATCH_TYPE_REGEXP = /:match:/

      def result
        return Event.new unless fixture

        @event = Event.new(event_attributes)
        attach_title!
        find_or_create_scopes!
        @event
      end

      private

      def fixture
        @payload
      end

      def title_fixture
        return tournament_fixture['sport'] if tournament_fixture.present?

        raise OddsFeed::InvalidMessageError, 'Tournament fixture not found'
      end

      def tournament_fixture
        return fixture['tournament'] if fixture['tournament'].present?

        raise OddsFeed::InvalidMessageError,
              'Tournament fixture must be present'
      end

      def season_fixture
        fixture['season']
      end

      def category_fixture
        tournament_fixture['category']
      end

      def event_attributes
        start_at_field = fixture['start_time'] || fixture['scheduled']

        { external_id: fixture['id'],
          start_at: start_at_field.to_time,
          name: event_name,
          description: event_name,
          payload: { competitors: fixture['competitors'],
                     liveodds:    fixture['liveodds'] } }
      end

      def event_name
        competitors = fixture['competitors']['competitor']
        raise NotImplementedError unless competitors.length == 2

        competitor1 = competitors[0]
        competitor2 = competitors[1]
        "#{competitor1['name']} VS #{competitor2['name']}"
      end

      def attach_title!
        log_job_message(:debug, "Title data received: #{title_fixture}")
        @event.title = EventAdapter::TitleSelector.call(payload: title_fixture)
      end

      def find_or_create_scopes!
        find_or_create_category!
        find_or_create_tournament!
        find_or_create_season!
      end

      def find_or_create_category!
        log_job_message(:debug, "Category data received: #{category_fixture}")

        unless category_fixture
          log_job_message(:info,
                          'Category fixture is missing in payload, exiting')
          return
        end

        @category = find_or_create_scope!(
          external_id: category_fixture['id'],
          name: category_fixture['name'],
          kind: EventScope::CATEGORY,
          title: @event.title
        )
      end

      def find_or_create_tournament!
        data = tournament_fixture
        log_job_message(:debug, "Tournament data received: #{data}")
        @tournament = find_or_create_scope!(
          external_id: data['id'],
          name: tournament_fixture['name'],
          event_scope: @category,
          kind: EventScope::TOURNAMENT,
          title: @event.title
        )
      end

      def find_or_create_season!
        log_job_message(:debug, "Season data received: #{season_fixture}")

        unless season_fixture
          log_job_message(:info,
                          'Season fixture is missing in payload, exiting')
          return
        end

        find_or_create_scope!(external_id: season_fixture['id'],
                              name: season_fixture['name'],
                              kind: EventScope::SEASON,
                              event_scope: @tournament,
                              title: @event.title)
      end

      def find_or_create_scope!(attributes)
        scope = EventScope.new(attributes)
        EventScope.create_or_update_on_duplicate(scope)
        @event.scoped_events.build(event_scope: scope)
        scope
      end
    end
  end
end
