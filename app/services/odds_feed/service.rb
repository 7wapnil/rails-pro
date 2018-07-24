module OddsFeed
  class Service < ApplicationService
    def initialize(api_client, payload)
      @api_client = api_client
      @payload = payload
    end

    def call
      event = find_or_create_event!(event_data['@event_id'])
      event_data['odds']['market'].each do |market_data|
        market = find_or_create_market!(event, market_data)
        market_data['outcome'].each do |odd_data|
          find_or_create_odd!(market, odd_data)
        end
      end

      # TODO: send updates to websocket
    end

    def find_or_create_event!(external_id)
      event = Event.find_by(external_id: external_id)
      return event unless event.nil?

      create_event(external_id)
    end

    def find_or_create_market!(event, market_data)
      external_id = market_id(market_data)
      market = Market.find_by(external_id: external_id)
      return market unless market.nil?

      Market.create!(event: event,
                     name: 'My market',
                     external_id: external_id,
                     priority: 0)
    end

    # rubocop:disable Metrics/MethodLength
    def find_or_create_odd!(market, odd_data)
      id = odd_id(market, odd_data)
      odd = Odd.find_by(external_id: id)
      if odd.nil?
        odd = Odd.create!(external_id: id,
                          name: 'My odd',
                          market: market,
                          value: odd_data['@odds'])
      else
        odd.update_attributes(value: odd_data['@odds'])
      end
      odd
    end
    # rubocop:enable Metrics/MethodLength

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

    def odd_id(market, odd_data)
      "#{market.id}:#{odd_data['@id']}"
    end
  end
end
