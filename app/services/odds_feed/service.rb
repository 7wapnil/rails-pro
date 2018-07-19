module OddsFeed
  class Service < ApplicationService
    def initialize(event_data)
      @event_data = event_data
      @api = Radar::Client.new
    end

    def call
      # store event
      # store markets
      # store odds
      # add new odd values
      # send updates to websocket
    end
  end
end
