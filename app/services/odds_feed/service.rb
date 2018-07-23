module OddsFeed
  class Service < ApplicationService
    def initialize(api_client, payload)
      @api_client = api_client
      @payload = payload
    end

    def call
      event = event(event_data['@event_id'])
      event_data['odds']['market'].each do |market_data|
        market(event, market_data)
      end
      # fetch odds
      # update odd values
      # send updates to websocket
    end

    def event(external_id)
      event = Event.find_by(external_id: external_id)
      return event unless event.nil?

      create_event(external_id)
    end

    def market(event, market_data)
      external_id = market_id(market_data)
      market = Market.find_by(external_id: external_id)
      return market unless market.nil?

      Market.create!(event: event,
                     name: 'My market',
                     external_id: external_id,
                     priority: 0)
    end

    private

    def event_data
      @payload['odds_change']
    end

    def create_event(external_id)
      event = @api_client.event(external_id).result
      event.save!
      event.title&.save!
      if event.event_scopes.length
        event.event_scopes.each { |scope| scope&.save! }
      end

      event
    end

    def market_id(market_data)
      return market_data['@id'] if market_data['@specifiers'].nil?
      "#{market_data['@id']}:#{market_data['@specifiers']}"
    end
  end
end
