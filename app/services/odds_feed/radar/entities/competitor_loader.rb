# frozen_string_literal: true

module OddsFeed
  module Radar
    module Entities
      class CompetitorLoader < BaseLoader
        NAME_SEPARATOR = ', '

        private

        def collect_data
          {
            competitors: competitor_data,
            players: player_names
          }
        end

        def competitor_data
          { entity_cache_key(external_id) => entity_name }
        end

        def cache_additional_entries
          Rails.cache.write_multi(
            player_names,
            cache: { expires_in: CACHE_TERM }
          )
        end

        def player_names
          Array
            .wrap(players_from_payload)
            .map { |attributes| attributes.values_at('id', 'full_name') }
            .to_h
            .transform_keys { |id| entity_cache_key(id) }
        end

        def players_from_payload
          payload.dig('players', 'player')
        end

        def payload
          @payload ||= OddsFeed::Radar::Client
                       .new
                       .competitor_profile(
                         external_id,
                         cache: { expires_in: Client::DEFAULT_CACHE_TERM }
                       )
                       .yield_self(&method(:read_payload))
        end

        def read_payload(converted_xml)
          converted_xml['competitor_profile'] ||
            converted_xml.fetch('simpleteam_profile')
        end

        def radar_entity_name
          payload
            .dig('competitor', 'name')
            .split(NAME_SEPARATOR)
            .reverse
            .join(' ')
        end
      end
    end
  end
end
