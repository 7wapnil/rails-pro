module OddsFeed
  module Radar
    class Transpiler
      def initialize(event, market_id, specifiers = '')
        @event = event
        @market_id = market_id
        @specifiers = specifiers
        @client = Client.new
      end

      def market_name
        transpile(template.name)
      end

      def odd_name(odd_id)
        collection = variant? ? variant_odds : template_odds
        template = odd_template(collection, odd_id)

        raise "Odd template ID #{odd_id} not found" if template.nil?
        transpile(template['name'])
      end

      def transpile(value)
        result = value
        value.scan(/\{([^\}]*)/).each do |matches|
          token = matches.first
          result = result.gsub("{#{token}}", token_value(token))
        end
        result
      end

      private

      def variant?
        template.payload['outcomes'].nil? && variant_value.present?
      end

      def token_value(token)
        tokens[token] || ''
      end

      def variant_value
        token_value('variant')
      end

      def tokens
        tokens = @specifiers.split('|')
                            .map { |spec| spec.split('=') }
                            .to_h

        competitors = @event.payload['competitors']['competitor']
        unless competitors.blank?
          competitors.each.with_index do |competitor, i|
            tokens["$competitor#{i + 1}"] = competitor['name']
          end
        end
        tokens
      end

      def template
        @template ||= MarketTemplate.find_by!(external_id: @market_id)
      end

      def template_odds
        template.payload
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
