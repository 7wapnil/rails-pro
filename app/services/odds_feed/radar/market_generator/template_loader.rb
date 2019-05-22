# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class TemplateLoader
        include JobLogger

        PLAYER_REGEX = /.*:player:.*/

        attr_reader :stored_template, :template, :api_client

        def initialize(event, stored_template, variant_id = nil)
          @event = event
          @api_client = OddsFeed::Radar::Client.new
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
          return template['name'].to_s if find_odd_template(external_id)

          return player_name(external_id) if player?(external_id)

          msg = 'Odd template not found'
          log_job_message(:error, message: msg, external_id: external_id)
          raise SilentRetryJobError
        end

        private

        attr_reader :variant_id, :event

        def player?(external_id)
          external_id.match?(PLAYER_REGEX)
        end

        def player_name(external_id)
          player = event.players.detect { |p| p.external_id == external_id } ||
                   radar_get_missing_player(external_id)

          player.full_name
        end

        def radar_get_missing_player(player_id)
          msg = 'Player not found in the competing teams'
          log_job_message(:warn, message: msg, external_id: player_id)

          player = Player.find_by(external_id: player_id)
          return player if player

          player_payload = api_client.player_profile(player_id)

          player = Player.from_radar_payload(player_payload)
          Player.create_or_ignore_on_duplicate(player)
          player
        end

        def find_odd_template(external_id)
          @template =
            outcomes.find { |outcome| outcome['id'] == external_id.to_s }
        end

        def outcomes
          Array.wrap(
            collection.dig('outcomes', 'outcome')
          )
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
