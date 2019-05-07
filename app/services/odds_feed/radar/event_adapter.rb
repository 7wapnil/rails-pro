module OddsFeed
  module Radar
    class EventAdapter < BaseAdapter
      include JobLogger

      MATCH_TYPE_REGEXP = /:match:/

      def result
        return Event.new unless fixture

        @event = EventFixtureBasedFactory.new(fixture: fixture).event
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

      def attach_title!
        log_job_message(
          :debug,
          message: 'Title data received',
          fixture: title_fixture
        )
        @event.title = EventAdapter::TitleSelector.call(payload: title_fixture)
      end

      def find_or_create_scopes!
        find_or_create_category!
        find_or_create_tournament!
        find_or_create_season!
      end

      def find_or_create_category!
        log_job_message(:debug, message: 'Category data received',
                                fixture: category_fixture)

        unless category_fixture
          log_job_message(:info, 'Category fixture is missing in payload')
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
        log_job_message(:debug, message: 'Tournament data received',
                                fixture: data)
        @tournament = find_or_create_scope!(
          external_id: data['id'],
          name: tournament_fixture['name'],
          event_scope: @category,
          kind: EventScope::TOURNAMENT,
          title: @event.title
        )
      end

      def find_or_create_season!
        log_job_message(:debug, message: 'Season data received',
                                fixture: season_fixture)

        unless season_fixture
          log_job_message(:info, 'Season fixture is missing in payload')
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
