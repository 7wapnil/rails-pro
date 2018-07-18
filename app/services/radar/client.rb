module Radar
  class Client
    include HTTParty

    base_uri ENV['RADAR_API_URL']
    format :xml

    def initialize
      @options = { headers: { "x-access-token": ENV['RADAR_API_TOKEN'],
                              "content-type": 'application/xml' } }
    end

    def who_am_i
      get_request('/users/whoami.xml')
    end

    def get_request(path)
      self.class.get(path, @options)
    end
  end
end
