# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketTemplates
      class CreateOrUpdate < ApplicationService
        include JobLogger

        VARIANT = 'variant'

        def initialize(market_data:, variant_outcomes_map:)
          @market_data = market_data
          @variant_outcomes_map = variant_outcomes_map
        end

        def call
          find_or_build_template!
          assign_template_attributes!
          assign_template_outcomes!
          template.save!

          log_success
        end

        private

        attr_reader :market_data, :variant_outcomes_map, :template

        def find_or_build_template!
          @template = MarketTemplate.find_or_initialize_by(
            external_id: market_data['id']
          )
        end

        def assign_template_attributes!
          template.assign_attributes(
            name: market_data['name'],
            groups: market_data['groups'],
            payload: {
              specifiers: market_data['specifiers'],
              attributes: market_data['attributes'],
              products: extract_market_data_products,
              variants: variants?
            }
          )
        end

        def extract_market_data_products
          return unless mappings_from_market_data

          Array
            .wrap(mappings_from_market_data['mapping'])
            .map { |mapping| mapping['product_id'] }
            .uniq
        end

        def variants?
          variant_specifier? && variant_mappings.any?
        end

        def variant_specifier?
          Array
            .wrap(market_data.dig('specifiers', 'specifier'))
            .any? { |specifier| specifier['name'] == VARIANT }
        end

        def assign_template_outcomes!
          template.payload.merge!(extract_market_data_outcomes)
        end

        def extract_market_data_outcomes
          return extract_variant_outcomes if template.variants?
          return {} if outcomes_from_market_data.blank?

          { outcomes: outcomes_from_market_data }
        end

        def outcomes_from_market_data
          @outcomes_from_market_data ||= market_data['outcomes'].to_h
        end

        def extract_variant_outcomes
          variant_mappings
            .map { |valid_for| valid_for.remove('variant=') }
            .map { |variant_id| map_variant_outcomes_row(variant_id) }
            .to_h
        end

        def variant_mappings
          @variant_mappings ||=
            Array.wrap(mappings_from_market_data['mapping'])
                 .map { |mapping| mapping['valid_for'] }
                 .compact
        end

        def mappings_from_market_data
          @mappings_from_market_data ||= market_data['mappings'].to_h
        end

        def map_variant_outcomes_row(variant_id)
          [variant_id, variant_outcomes_map[variant_id]]
        end

        def log_success
          log_job_message(:debug, "Market template id '#{template.id}' updated")
        end
      end
    end
  end
end
