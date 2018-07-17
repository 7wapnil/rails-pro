module Radar
  class Client
    include HTTParty

    base_uri ENV['RADAR_API_URL']

    def initialize
      @options = { headers: { "x-access-token": ENV['RADAR_API_TOKEN'],
                              "content-type": "application/xml" } }
    end

    def who_am_i
      self.class.get('/users/whoami.xml', @options)
    end
  end
end
