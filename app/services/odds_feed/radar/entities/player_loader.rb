# frozen_string_literal: true

module OddsFeed
  module Radar
    module Entities
      class PlayerLoader < BaseLoader
        private

        def radar_entity_name
          ::OddsFeed::Radar::Client
            .instance
            .player_profile(
              external_id,
              cache: { expires_in: Client::DEFAULT_CACHE_TERM }
            )
            .dig('player_profile', 'player', 'full_name')
        end
      end
    end
  end
end
