module OddsFeed
  class Service < ApplicationService
    def initialize(api_client, payload)
      @api_client = api_client
      @payload = payload
    end

    def call
      event = find_or_create_event!(event_data['@event_id'])
      event_data['odds']['market'].each do |market_data|
        generate_market!(event, market_data)
      end
    end

    private

    def event_data
      @payload['odds_change']
    end

    def find_or_create_event!(external_id)
      event = Event.find_by(external_id: external_id)
      return event unless event.nil?

      create_event(external_id)
    end

    def create_event(external_id)
      event = request_event(external_id)
      event.save!
      event.title&.save!
      if event.event_scopes.any?
        event.event_scopes.each { |scope| scope&.save! }
      end
      event
    end

    def request_event(id)
      @api_client.event(id).result
    end

    def generate_market!(event, market_data)
      MarketGenerator.new(event, market_data).generate
    end
  end
end
