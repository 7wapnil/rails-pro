module OddsFeed
  module Radar
    class EventAdapter < BaseAdapter
      def result
        event = Event.new event_data
        event.build_title title_data(event)
        event.event_scopes.build tournament_data(event)
        event.event_scopes.build season_data(event)
        event.event_scopes.build country_data(event)

        event
      end

      private

      def fixture
        @payload['fixtures_fixture']['fixture']
      end

      def event_data
        { external_id: fixture['id'],
          name: event_name,
          payload: { competitors: fixture['competitors'] } }
      end

      def title_data(_event)
        sport_data = fixture['tournament']['sport']
        { external_id: sport_data['id'], name: sport_data['name'] }
      end

      def tournament_data(event)
        tournament_data = fixture['tournament_round']
        { external_id: tournament_data['betradar_id'],
          name: tournament_data['group_long_name'],
          kind: :tournament,
          title: event.title }
      end

      def season_data(event)
        season_data = fixture['season']
        { external_id: season_data['id'],
          name: season_data['name'],
          kind: :season,
          title: event.title }
      end

      def country_data(event)
        country_data = fixture['tournament']['category']
        { external_id: country_data['id'],
          name: country_data['name'],
          kind: :country,
          title: event.title }
      end

      def event_name
        competitors = fixture['competitors']['competitor']
        raise NotImplementedError unless competitors.length == 2
        competitor1 = competitors[0]
        competitor2 = competitors[1]
        "#{competitor1['name']} VS #{competitor2['name']}"
      end
    end
  end
end
