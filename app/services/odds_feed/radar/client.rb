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
        get_request('/users/whoami.xml')
      end

      def get_event(id)
        payload = get_request "/sports/#{@language}/sport_events/#{id}/fixture.xml"
        EventAdapter.new(payload)
      end

      def get_request(path)
        self.class.get(path, @options)
      end
    end
  end
end
