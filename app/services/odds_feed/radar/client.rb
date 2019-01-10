module OddsFeed
  module Radar
    class Client
      include HTTParty
      include JobLogger

      DEFAULT_CACHE_TERM = 12.hours

      base_uri ENV['RADAR_API_URL']
      headers 'x-access-token': ENV['RADAR_API_TOKEN']
      format :xml
      raise_on [403, 404, 409, 500, 503]

      def initialize
        @language = 'en'
      end

      def who_am_i
        request('/users/whoami.xml')
      end

      def event(id, cache: nil)
        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        payload = request(route, cache: cache)
                  .dig('fixtures_fixture', 'fixture')
        EventAdapter.new(payload)
      end

      def events_to_date(date, cache: nil)
        formatted_date = date.to_s
        route = "/sports/#{@language}/schedules/#{formatted_date}/schedule.xml"
        response = request(route, cache: cache)
        events_payload = response['schedule']['sport_event']
        events_payload.map do |event_payload|
          EventAdapter.new(event_payload)
        end
      end

      def book_live_coverage(id)
        route = "/liveodds/booking-calendar/events/#{id}/book"
        post(route)
      end

      def product_recovery_initiate_request(product_code:, after:, **query)
        raise ArgumentError unless recovery_request_query_is_valid?(query)

        query_params = query.merge(after: after.to_i).to_query

        route = URI::HTTP
                .build(
                  path: "/#{product_code}/recovery/initiate_request",
                  query: query_params
                )
                .request_uri

        log_job_message(:info, "Calling subscription recovery on #{route}")
        post(route)
      end

      # Market templates descriptions request
      # Returns a list of market templates with outcome name, specifiers
      # and attributes
      def markets(cache: nil)
        route = "/descriptions/#{@language}/markets.xml?include_mappings=false"
        request(route, cache: cache)
      end

      # All available tournaments for all sports request
      # Returns a list of tournaments with sport, category, current season
      # and season coverage
      def tournaments(cache: nil)
        route = "/sports/#{@language}/tournaments.xml"
        request(route, cache: cache)
      end

      def market_variants(market_id, variant_urn, cache: nil)
        route = [
          '/descriptions',
          @language,
          'markets',
          market_id,
          'variants',
          variant_urn
        ].join('/')

        log_job_message(:info, "Loading market template on: #{route}")
        request(route, cache: cache)
      end

      def player_profile(player_id, cache: nil)
        route = "/sports/#{@language}/players/#{player_id}/profile.xml"
        log_job_message(:info, "Loading player profile: #{route}")
        request(route, cache: cache)
      end

      def competitor_profile(competitor_id, cache: nil)
        route = "/sports/#{@language}/competitors/#{competitor_id}/profile.xml"
        log_job_message(:info, "Loading competitor profile: #{route}")
        request(route, cache: cache)
      end

      def venue_summary(venue_id, cache: nil)
        route = "/sports/#{@language}/venues/#{venue_id}/profile.xml"
        log_job_message(:info, "Loading venue summary: #{route}")
        request(route, cache: cache)
      end

      def request(path, method: :get, cache: nil)
        ResponseReader.call(path: path, method: method, cache: cache)
      end

      def post(path)
        request(path, method: :post)
      end

      private

      def recovery_request_query_is_valid?(query)
        allowed_params = %i[request_id node_id]
        query.keys.all? { |param| allowed_params.include?(param) }
      end
    end
  end
end
