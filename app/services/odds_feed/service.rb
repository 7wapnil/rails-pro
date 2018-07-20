module OddsFeed
  class Service < ApplicationService
    def initialize(event_data)
      @event_data = event_data
      @api = Radar::Client.new
    end

    def call
      event_id = 'sr:match:8696826'
      store_event(event_id)
      # store event
      # store markets
      # store odds
      # add new odd values
      # send updates to websocket
    end

    def store_event(external_id)
      event_adapter = @api.get_event external_id
    end
  end
end
