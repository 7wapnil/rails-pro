module OddsFeed
  module Radar
    class Transpiler
      def initialize(event, market_id, specifiers = '')
        @event = event
        @market_id = market_id
        @client = Client.new
        @tokens = specifiers.split('|')
                            .map { |spec| spec.split('=') }
                            .to_h
      end

      def market_name
        transpile(market_template.name)
      end

      def odd_name(odd_id)
        collection = variant? ? variant_odds : template_odds
        template = odd_template(collection, odd_id)

        raise "Odd template ID #{odd_id} not found" if template.nil?

        transpile(template['name'])
      end

      def transpile(value)
        interpreter.parse(value)
      end

      private

      def interpreter
        @interpreter ||= OddsFeed::Radar::Transpiling::Interpreter
                         .new(@event, @tokens)
      end

      def variant?
        market_template.payload['outcomes'].nil? && variant_value.present?
      end

      def token_value(token)
        @tokens[token] || ''
      end

      def variant_value
        token_value('variant')
      end

      def market_template
        @market_template ||= MarketTemplate.find_by!(external_id: @market_id)
      end

      def template_odds
        market_template.payload
      end

      def variant_odds
        @variant_odds ||= @client.market_variants(
          @market_id,
          variant_value
        )['market_descriptions']['market']
      end

      def odd_template(collection, odd_id)
        return if collection['outcomes'].nil?
        return if collection['outcomes']['outcome'].empty?

        collection['outcomes']['outcome'].find do |outcome|
          outcome['id'] == odd_id
        end
      end
    end
  end
end
