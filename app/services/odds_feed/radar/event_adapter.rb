module OddsFeed
  module Radar
    class EventAdapter < BaseAdapter
      def result
        @event = Event.new event_attributes
        find_or_create_title!
        find_or_create_tournament!
        find_or_create_season!
        find_or_create_country!
        @event
      end

      private

      def fixture
        @payload['fixtures_fixture']['fixture']
      end

      def title_fixture
        fixture['tournament']['sport']
      end

      def tournament_fixture
        fixture['tournament_round']
      end

      def season_fixture
        fixture['season']
      end

      def country_fixture
        fixture['tournament']['category']
      end

      def event_attributes
        { external_id: fixture['id'],
          start_at: fixture['start_time'].to_time,
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

      def find_or_create_title!
        Rails.logger.info "Title data received: #{title_fixture}"
        title = Title
                .create_with(name: title_fixture['name'])
                .find_or_create_by!(external_id: title_fixture['id'])
        @event.title = title
      end

      def find_or_create_tournament!
        data = tournament_fixture
        Rails.logger.info "Tournament data received: #{data}"
        tournament = EventScope
                     .find_or_create_by!(external_id: data['betradar_id'],
                                         kind: :tournament,
                                         name: data['group_long_name'],
                                         title: @event.title)
        @event.event_scopes << tournament
      end

      def find_or_create_season!
        Rails.logger.info "Season data received: #{season_fixture}"
        season = EventScope
                 .find_or_create_by!(external_id: season_fixture['id'],
                                     name: season_fixture['name'],
                                     kind: :season,
                                     title: @event.title)
        @event.event_scopes << season
      end

      def find_or_create_country!
        Rails.logger.info "Country data received: #{country_fixture}"
        country = EventScope
                  .find_or_create_by!(external_id: country_fixture['id'],
                                      name: country_fixture['name'],
                                      kind: :country,
                                      title: @event.title)
        @event.event_scopes << country
      end
    end
  end
end
