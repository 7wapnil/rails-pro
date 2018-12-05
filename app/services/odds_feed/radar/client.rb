module OddsFeed
  module Radar
    class Client
      include HTTParty

      base_uri ENV['RADAR_API_URL']
      format :xml

      def initialize
        @language = 'en'
        @options = { headers: { "x-access-token": ENV['RADAR_API_TOKEN'] } }
      end

      def who_am_i
        request('/users/whoami.xml')
      end

      def event(id)
        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        payload = request(route)['fixtures_fixture']['fixture']
        EventAdapter.new(payload)
      end

      def events_to_date(date)
        formatted_date = date.to_s
        route = "/sports/#{@language}/schedules/#{formatted_date}/schedule.xml"
        response = request(route)
        events_payload = response['schedule']['sport_event']
        events_payload.map do |event_payload|
          EventAdapter.new(event_payload)
        end
      end

      def book_live_coverage(id)
        route = "/liveodds/booking-calendar/events/#{id}/book"
        request(route, method: :post)
      end

      def product_recovery_initiate_request(product_code:, after: nil)
        route = "/#{product_code}/recovery/initiate_request"
        route += "?after=#{after}" if after

        Rails.logger.info("Calling subscription recovery on #{route}")
        post(route)
      end

      # Market templates descriptions request
      # Returns a list of market templates with outcome name, specifiers
      # and attributes
      def markets
        route = "/descriptions/#{@language}/markets.xml?include_mappings=false"
        request(route)
      end

      # All available tournaments for all sports request
      # Returns a list of tournaments with sport, category, current season
      # and season coverage
      def tournaments
        route = "/sports/#{@language}/tournaments.xml"
        request(route)
      end

      def market_variants(market_id, variant_urn)
        route = [
          '/descriptions',
          @language,
          'markets',
          market_id,
          'variants',
          variant_urn
        ].join('/')

        Rails.logger.info "Loading market template on: #{route}"
        request(route)
      end

      def request(path, method: :get)
        Rails.logger.debug "Requesting Radar API endpoint: #{path}"
        response = self.class.send(method, path, @options).parsed_response
        validate_response(response)
        response
      rescue RuntimeError, MultiXml::ParseError => e
        Rails.logger.error e.message
        raise HTTParty::InvalidResponseError, 'Failed to parse API response'
      end

      def validate_response(response)
        Rails.logger.debug "Radar API response: #{response}"
        error = response['error']
        raise OddsFeed::InvalidResponseError, error['message'] if error
      end

      def post(path)
        request(path, method: :post)
      end
    end
  end
end
