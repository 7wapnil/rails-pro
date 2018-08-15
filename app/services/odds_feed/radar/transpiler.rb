module OddsFeed
  module Radar
    class Transpiler
      def initialize(event, market_id, specifiers = '')
        @event = event
        @market_id = market_id
        @specifiers = specifiers
      end

      def market_name
        transpile(template.name)
      end

      def odd_name(odd_id)
        template = odd_template(odd_id)
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

      def token_value(token)
        tokens[token] || ''
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

      def odd_template(odd_id)
        return if template.payload['outcomes']['outcome'].nil?
        odd = template.payload['outcomes']['outcome'].find do |outcome|
          outcome['id'] == odd_id
        end
        odd
      end
    end
  end
end
