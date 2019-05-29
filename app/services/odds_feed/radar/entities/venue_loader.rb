# frozen_string_literal: true

module OddsFeed
  module Radar
    module Entities
      class VenueLoader < BaseLoader
        private

        def radar_entity_name
          ::OddsFeed::Radar::Client
            .instance
            .venue_summary(
              external_id,
              cache: { expires_in: Client::DEFAULT_CACHE_TERM }
            )
            .dig('venue_summary', 'venue', 'name')
        end
      end
    end
  end
end
