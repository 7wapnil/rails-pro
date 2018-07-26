module OddsFeed
  class MarketGenerator
    def initialize(event, market_data)
      @event = event
      @market_data = market_data
    end

    def generate
      market = Market.find_or_initialize_by(external_id: market_id,
                                            event: @event)
      market.assign_attributes({ name: transpiler.transpile(template.name),
                                 priority: 0,
                                 status: 1 })
      market.save!
      generate_odds!(market)
    end

    private

    def market_id
      "#{@event.external_id}:#{@market_data['@id']}"
    end

    def generate_odds!(market)
      return if @market_data['outcome'].nil?
      @market_data['outcome'].each do |odd_data|
        generate_odd!(market, odd_data)
      end
    end

    def generate_odd!(market, odd_data)
      odd_id = "#{market.external_id}:#{odd_data['@id']}"
      odd = Odd.find_or_initialize_by(external_id: odd_id,
                                      market: market)
      odd_name = transpiler.transpile(odd_template(odd_data['@id']))
      odd.assign_attributes({ name: odd_name,
                              status: odd_data['@active'],
                              value: odd_data['@odds']})
      odd.save!
    end

    def odd_template(odd_id)
      odd_template = template.payload['outcomes']&.find do |item|
        item['@id'] == odd_id
      end
      raise "Odd template id #{odd_id} not found" if odd_template.nil?
      odd_template
    end

    def transpiler
      @transpiler ||= Transpiler.new(tokens)
    end

    def template
      @template ||= MarketTemplate.find_by!(external_id: @market_data['@id'])
    end

    def tokens
      return {} unless @market_data['@specifiers']
      tokens = @market_data['@specifiers']
            .split('|')
            .map { |spec| spec.split('=') }
            .to_h

      unless @event.payload['competitors'].blank?
        @event.payload['competitors'].each do |competitor, i|
          tokens["$competitor#{i}"] = competitor['@name']
        end
      end
      tokens
    end
  end
end
