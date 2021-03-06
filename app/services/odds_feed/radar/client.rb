# frozen_string_literal: true

module OddsFeed
  module Radar
    class Client # rubocop:disable Metrics/ClassLength
      include HTTParty
      include JobLogger
      include Singleton

      DEFAULT_CACHE_TERM = 12.hours
      WARNING_CODES = [500, 503].freeze

      base_uri ENV['RADAR_API_URL']
      headers 'x-access-token': ENV['RADAR_API_TOKEN']
      parser ::HTTParty::ImprovedXmlParser
      format :xml
      raise_on [403, 404, 409, 500, 503]

      def initialize
        @language = 'en'
      end

      def who_am_i
        request('/users/whoami.xml')
      end

      # rubocop:disable Metrics/MethodLength
      def event(id, cache: nil)
        validate_external_id!(id)

        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        payload = request(route, cache: cache)
                  .dig('fixtures_fixture', 'fixture')

        unless payload
          log_job_message(:warn, message: 'Payload for event is missing',
                                 event_id: id)
        end

        EventAdapter.new(payload)
      rescue Events::UnsupportedPayloadError => e
        log_job_message(:error, message: e.message,
                                event_id: id,
                                error_object: e)

        EventAdapter.new
      end
      # rubocop:enable Metrics/MethodLength

      def event_raw(id, cache: nil)
        validate_external_id!(id)

        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        request(route, cache: cache)
      rescue Events::UnsupportedPayloadError => e
        log_job_message(:error, message: e.message,
                                event_id: id,
                                error_object: e)

        raise SilentRetryJobError, "Event is not supported. Event id: #{id}"
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
      rescue HTTParty::ResponseError => error
        raise unless warning_code?(error)

        log_job_message(:warn,
                        message: "#{error.response.code} response received")

        raise SilentRetryJobError, "#{error.response.code} response received"
      end

      def warning_code?(error)
        error.response.is_a?(Net::HTTPResponse) &&
          WARNING_CODES.include?(error.response.code.to_i)
      end

      def post(path)
        request(path, method: :post)
      end

      private

      def validate_external_id!(id)
        return if id.to_s.match?(EventAdapter::MATCH_TYPE_REGEXP)

        raise Events::UnsupportedPayloadError, 'Payload is not supported yet'
      end

      def recovery_request_query_is_valid?(query)
        allowed_params = %i[request_id node_id]
        query.keys.all? { |param| allowed_params.include?(param) }
      end
    end
  end
end
