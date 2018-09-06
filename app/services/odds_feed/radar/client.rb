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
        EventAdapter.new(request(route))
      end

      def product_recovery_initiate_request(product_code:, after: nil)
        route = "/#{product_code}/recovery/initiate_request"
        route += "?after=#{after}" if after
        post(route)
      end

      # Market templates descriptions request
      # Returns a list of market templates with outcome name, specifiers
      # and attributes
      def markets
        route = "/descriptions/#{@language}/markets.xml?include_mappings=false"
        request(route)
      end

      def request(path, method: :get)
        Rails.logger.debug "Requesting Radar API endpoint: #{path}"
        response = self.class.send(method, path, @options).parsed_response
        Rails.logger.debug "Radar API response: #{response}"
        response
      end

      def post(path)
        request(path, method: :post)
      end
    end
  end
end
