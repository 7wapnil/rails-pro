module OddsFeed
  class MarketGenerator
    def initialize(event, payload)
      @event = event
      @payload = payload
    end

    def generate
      market = Market.find_or_initialize_by(external_id: external_id,
                                            event: @event)
      market.assign_attributes(name: 'Yo man',
                               priority: 0,
                               status: 1)
      market.save!
      generate_odds!(market)
    end

    private

    def external_id
      "#{@event.external_id}:#{@payload['@id']}"
    end

    def generate_odds!(market)
    end

    def template
      @template ||= MarketTemplate.find(@payload['@id'])
    end
  end
end
