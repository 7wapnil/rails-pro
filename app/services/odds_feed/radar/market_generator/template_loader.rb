# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class TemplateLoader
        include JobLogger

        PLAYER_REGEX = /.*:player:.*/

        attr_reader :stored_template

        def initialize(event, stored_template, variant_id = nil)
          @event = event
          @stored_template = stored_template
          @variant_id = variant_id
        end

        def market_name
          stored_template.name
        end

        def market_category
          stored_template.category
        end

        def odd_name(external_id)
          template = find_odd_template(external_id)
          return template['name'].to_s if template

          return player_name(external_id) if player?(external_id)

          raise "Odd template ID #{external_id} not found"
        end

        private

        attr_reader :variant_id, :event

        def player?(external_id)
          external_id.match?(PLAYER_REGEX)
        end

        def player_name(external_id)
          player = event.players.detect { |p| p.external_id == external_id }
          return player.full_name if player

          raise "Player ID #{external_id} not found"
        end

        def find_odd_template(external_id)
          outcomes.find { |outcome| outcome['id'] == external_id.to_s }
        end

        def outcomes
          notify_outcome_is_empty if outcome_empty?

          Array.wrap(outcome_list)
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
          stored_template.variants? && variant_id.present?
        end

        def market_id
          stored_template.external_id
        end

        def notify_outcome_is_empty
          log_job_message(:warn, "Outcome data is empty for MarketTemplate
                                  with external_id '#{market_id}'")
        end

        def variant_odds
          stored_template.payload[variant_id] || radar_variant_odds
        end

        def radar_variant_odds
          OddsFeed::Radar::Client
            .new
            .market_variants(
              market_id,
              variant_id,
              cache: { expires_in: Client::DEFAULT_CACHE_TERM }
            )
            .dig('market_descriptions', 'market')
        end
      end
    end
  end
end
