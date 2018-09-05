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
        title = Title
                .create_with(name: title_fixture['name'])
                .find_or_create_by!(external_id: title_fixture['id'])
        @event.title = title
        Rails.logger.info "Title '#{title.name}' attached to event"
      end

      def find_or_create_tournament!
        data = tournament_fixture
        tournament = EventScope
                     .create_with(title: @event.title)
                     .find_or_create_by!(external_id: data['betradar_id'],
                                         kind: :tournament,
                                         name: data['group_long_name'])
        @event.event_scopes << tournament
        Rails.logger.info "Tournament '#{tournament.name}' attached to event"
      rescue ActiveRecord::RecordInvalid
        Rails.logger.warn "Invalid tournament data: #{data}"
      end

      def find_or_create_season!
        season = EventScope
                 .create_with(title: @event.title)
                 .find_or_create_by!(external_id: season_fixture['id'],
                                     name: season_fixture['name'],
                                     kind: :season)
        @event.event_scopes << season
        Rails.logger.info "Season '#{season.name}' attached to event"
      rescue ActiveRecord::RecordInvalid
        Rails.logger.warn "Invalid season data: #{season_fixture}"
      end

      def find_or_create_country!
        country = EventScope
                  .create_with(title: @event.title)
                  .find_or_create_by!(external_id: country_fixture['id'],
                                      name: country_fixture['name'],
                                      kind: :country)
        @event.event_scopes << country
        Rails.logger.info "Country '#{country.name}' attached to event"
      rescue ActiveRecord::RecordInvalid
        Rails.logger.warn "Invalid country data: #{country_fixture}"
      end
    end
  end
end
