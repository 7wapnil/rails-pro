module OddsFeed
  module Radar
    class Client
      include HTTParty

      base_uri ENV['RADAR_API_URL']
      format :xml

      def initialize
        @language = 'en'
        @options = { headers: { "x-access-token": ENV['RADAR_API_TOKEN'],
                                "content-type": 'application/xml' } }
      end

      def who_am_i
        request('/users/whoami.xml')
      end

      def event(id)
        route = "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        EventAdapter.new(request(route))
      end

      # Respect rates
      def subscription_recovery(product_code:, start_at: nil)
        route = "/#{product_code}/recovery/initiate_request"
        route += "?after=#{start_at}" if start_at
        post(route)
      end

      # Market templates descriptions request
      # Returns a list of market templates with outcome name, specifiers
      # and attributes
      def markets
        route = "/descriptions/#{@language}/markets.xml?include_mappings=false"
        request(route)
      end

      def request(path)
        self.class.get(path, @options).parsed_response
      end

      # TODO: Rquest with method option
      def post(path)
        self.class.post(path, @options).parsed_response
      end
    end
  end
end
