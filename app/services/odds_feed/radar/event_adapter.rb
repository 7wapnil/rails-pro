module OddsFeed
  module Radar
    class EventAdapter < BaseAdapter
      def result
        event = Event.new event_data
        event.title = title
        event.event_scopes << tournament(event)
        event.event_scopes << season(event)
        event.event_scopes << country(event)
        event
      end

      private

      def fixture
        @payload['fixtures_fixture']['fixture']
      end

      def event_data
        { external_id: fixture['id'],
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

      def title
        sport_data = fixture['tournament']['sport']
        title = Title.find_by(external_id: sport_data['id'])
        return title unless title.nil?

        Rails.logger.info "Create new title '#{sport_data['name']}'"
        Title.create(external_id: sport_data['id'],
                     name: sport_data['name'])
      end

      def tournament(event)
        tournament_data = fixture['tournament_round']
        external_id = tournament_data['betradar_id']
        tournament = EventScope.find_by(external_id: external_id)
        return tournament unless tournament.nil?

        name = tournament_data['group_long_name']
        Rails.logger.info "Create new tournament scope '#{name}'"
        EventScope.create(external_id: external_id,
                          name: name,
                          kind: :tournament,
                          title: event.title)
      end

      def season(event)
        season_data = fixture['season']
        season = EventScope.find_by(external_id: season_data['id'])
        return season unless season.nil?

        Rails.logger.info "Create new season scope '#{season_data['name']}'"
        EventScope.create(external_id: season_data['id'],
                          name: season_data['name'],
                          kind: :season,
                          title: event.title)
      end

      def country(event)
        country_data = fixture['tournament']['category']
        country = EventScope.find_by(external_id: country_data['id'])
        return country unless country.nil?

        Rails.logger.info "Create new country scope '#{country_data['name']}'"
        EventScope.create(external_id: country_data['id'],
                          name: country_data['name'],
                          kind: :country,
                          title: event.title)
      end
    end
  end
end
