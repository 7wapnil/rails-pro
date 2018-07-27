module OddsFeed
  module Radar
    class MarketGenerator
      def initialize(event, market_data)
        @event = event
        @market_data = market_data
      end

      def generate
        external_id = "#{@event.external_id}:#{@market_data['@id']}"
        market = Market.find_or_initialize_by(external_id: external_id,
                                              event: @event)
        market.assign_attributes({ name: transpiler.market_name,
                                   priority: 0,
                                   status: 1 })
        market.save!
        generate_odds!(market)
      end

      private

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
        odd.assign_attributes({ name: transpiler.odd_name(odd_data['@id']),
                                status: odd_data['@active'],
                                value: odd_data['@odds']})
        odd.save!
      end

      def transpiler
        @transpiler ||= Transpiler.new(@event,
                                       @market_data['@id'],
                                       @market_data['@specifiers'])
      end
    end
  end
end
