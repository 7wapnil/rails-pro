module OddsFeed
  module Radar
    class Client # rubocop:disable Metrics/ClassLength
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
        unless supported_external_id?(id)
          log_job_message(:error, message: 'Payload is not supported yet',
                                  event_id: id)

          return EventAdapter.new
        end

        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        payload = request(route, cache: cache)
                  .dig('fixtures_fixture', 'fixture')

        unless payload
          log_job_message(:warn, message: 'Payload for event is missing',
                                 event_id: id)
        end

        EventAdapter.new(payload)
      end

      def event_raw(id, cache: nil)
        unless supported_external_id?(id)
          log_job_message(:error, message: 'Event is not supported',
                                  event_id: id)
          raise SilentJobRetryError
        end

        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        request(route, cache: cache)
      end

      def events_for_date(date, cache: nil)
        formatted_date = date.to_s
        route = "/sports/#{@language}/schedules/#{formatted_date}/schedule.xml"
        response = request(route, cache: cache)
        events_payload = response['schedule']['sport_event']
        events_payload.compact.map do |event_payload|
          EventAdapter.new(event_payload)
        end
      end

      def book_live_coverage(id)
        route = "/liveodds/booking-calendar/events/#{id}/book"
        post(route)
      end

      def product_recovery_initiate_request(product_code:, after:, **query)
        raise ArgumentError unless recovery_request_query_is_valid?(query)

        milliseconds_timestamp = after.to_datetime.strftime('%Q')
        query_params = query.merge(after: milliseconds_timestamp).to_query
        route = URI::HTTP
                .build(
                  path: "/#{product_code}/recovery/initiate_request",
                  query: query_params
                ).request_uri

        log_job_message(:info, message: 'Calling subscription recovery',
                               route: route)
        post(route)
      end

      # Market templates descriptions request
      # Returns a list of market templates with outcome name, specifiers
      # and attributes
      def markets(include_mappings: false, cache: nil)
        route = "/descriptions/#{@language}/markets.xml"
        options = { query: { include_mappings: include_mappings } }
        request(route, cache: cache, options: options)
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

        log_job_message(:info, message: 'Loading market template',
                               route: route)
        request(route, cache: cache)
      end

      def all_market_variants(cache: nil)
        route = "/descriptions/#{@language}/variants.xml"

        log_job_message(:info, message: 'Loading all market templates',
                               route: route)
        request(route, cache: cache)
      end

      def player_profile(player_id, cache: nil)
        route = "/sports/#{@language}/players/#{player_id}/profile.xml"
        log_job_message(:info, message: 'Loading player profile',
                               route: route)
        request(route, cache: cache)
      end

      def competitor_profile(competitor_id, cache: nil)
        route = "/sports/#{@language}/competitors/#{competitor_id}/profile.xml"
        log_job_message(:info, message: 'Loading competitor profile',
                               route: route)
        request(route, cache: cache)
      end

      def venue_summary(venue_id, cache: nil)
        route = "/sports/#{@language}/venues/#{venue_id}/profile.xml"
        log_job_message(:info, message: 'Loading venue summary',
                               route: route)
        request(route, cache: cache)
      end

      def request(path, method: :get, cache: nil, **options)
        ResponseReader.call(path: path, method: method, cache: cache, **options)
      end

      def post(path)
        request(path, method: :post)
      end

      private

      def supported_external_id?(id)
        id.to_s.match?(EventAdapter::MATCH_TYPE_REGEXP)
      end

      def recovery_request_query_is_valid?(query)
        allowed_params = %i[request_id node_id]
        query.keys.all? { |param| allowed_params.include?(param) }
      end
    end
  end
end
