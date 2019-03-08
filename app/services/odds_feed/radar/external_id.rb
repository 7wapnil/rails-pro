module OddsFeed
  module Radar
    class ExternalId
      attr_writer :event_id, :market_id, :specs, :outcome_id

      def self.generate(*args, &block)
        new(*args, &block).generate
      end

      def initialize(event_id: nil, market_id: nil, specs: nil, outcome_id: nil)
        @event_id = event_id
        @market_id = market_id
        @specs = specs
        @outcome_id = outcome_id
      end

      def generate
        market_id = generate_market_id

        id_parts = []
        id_parts.push(@event_id) unless @event_id.nil?
        id_parts.push(market_id) unless market_id.nil?
        id_parts.push(@outcome_id) unless @outcome_id.nil?

        id_parts.join(':')
      end

      private

      def generate_market_id
        return @market_id unless @specs.present?

        "#{@market_id}/#{@specs}"
      end
    end
  end
end
