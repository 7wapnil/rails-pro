module OddsFeed
  class Service < ApplicationService
    def initialize(api_client, payload)
      @api_client = api_client
      @payload = payload
    end

    def call
      event(event_data['@event_id'])
      # fetch markets
      # fetch odds
      # update odd values
      # send updates to websocket
    end

    def event(external_id)
      event = Event.find_by(external_id: external_id)
      return event unless event.nil?

      @api_client.event external_id
    end

    private

    def event_data
      @payload['odds_change']
    end
  end
end
