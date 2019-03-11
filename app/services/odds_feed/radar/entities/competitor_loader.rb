# frozen_string_literal: true

module OddsFeed
  module Radar
    module Entities
      class CompetitorLoader < BaseLoader
        NAME_SEPARATOR = ', '

        private

        def cache_additional_entries
          Rails.cache.write_multi(
            player_names,
            cache: { expires_in: CACHE_TERM }
          )
        end

        def player_names
          payload
            .dig('players', 'player')
            .to_a
            .map { |attributes| attributes.values_at('id', 'full_name') }
            .to_h
            .transform_keys { |id| entity_cache_key(id) }
        end

        def payload
          @payload ||= OddsFeed::Radar::Client
                       .new
                       .competitor_profile(
                         external_id,
                         cache: { expires_in: Client::DEFAULT_CACHE_TERM }
                       )
                       .fetch('competitor_profile')
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
