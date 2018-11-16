module OddsFeed
  module Radar
    module MarketGenerator
      class TemplateLoader
        def initialize(market_id, variant_id = nil)
          @market_id = market_id
          @variant_id = variant_id
        end

        def market_name
          stored_template.name
        end

        def odd_name(id)
          template = find_odd_template(id)
          raise "Odd template ID #{id} not found" if template.nil?

          template['name'] || ''
        end

        private

        def stored_template
          @stored_template ||= MarketTemplate.find_by!(external_id: @market_id)
        end

        def find_odd_template(id)
          outcomes.find { |outcome| outcome['id'] == id }
        end

        def variant?
          stored_template.payload['outcomes'].nil? && @variant_id.present?
        end

        def outcomes
          collection = variant? ? variant_odds : stored_template.payload
          return [] if collection['outcomes'].nil?
          return [] if collection['outcomes']['outcome'].empty?

          collection['outcomes']['outcome']
        end

        def variant_odds
          @variant_odds ||= OddsFeed::Radar::Client.new.market_variants(
            @market_id,
            @variant_id
          )['market_descriptions']['market']
        end
      end
    end
  end
end
