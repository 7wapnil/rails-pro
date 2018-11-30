module OddsFeed
  module Radar
    module MarketGenerator
      class TemplateLoader
        def initialize(market_id, variant_id = nil)
          @market_id  = market_id
          @variant_id = variant_id
        end

        def market_name
          stored_template.name
        end

        def odd_name(id)
          template = find_odd_template(id)

          raise "Odd template ID #{id} not found" if template.nil?

          template['name'].to_s
        end

        private

        attr_reader :market_id, :variant_id

        def stored_template
          @stored_template ||= MarketTemplate.find_by!(external_id: market_id)
        end

        def find_odd_template(id)
          return outcomes.first if variant_id.blank? && outcomes.one?

          outcomes.find { |outcome| outcome['id'] == id }
        end

        def outcomes
          notify_outcome_is_empty if outcome_empty?

          outcome_list.is_a?(Hash) ? [outcome_list] : outcome_list
        end

        def outcome_empty?
          collection['outcomes'].nil? || outcome_list.nil?
        end

        def outcome_list
          @outcome_list ||= collection.dig('outcomes', 'outcome')
        end

        def collection
          @collection ||= variant? ? variant_odds : stored_template.payload
        end

        def variant?
          stored_template.payload['outcomes'].nil? && variant_id.present?
        end

        def notify_outcome_is_empty
          Rails.logger.warn("Outcome data is empty for MarketTemplate
                             with external_id '#{market_id}'")
        end

        def variant_odds
          @variant_odds ||= OddsFeed::Radar::Client
                            .new
                            .market_variants(market_id, variant_id)
                            .dig('market_descriptions', 'market')
        end
      end
    end
  end
end
