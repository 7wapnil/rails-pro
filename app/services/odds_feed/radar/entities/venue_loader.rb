module OddsFeed
  module Radar
    module Entities
      class VenueLoader < BaseLoader
        private

        def radar_entity_name
          OddsFeed::Radar::Client
            .new
            .venue_summary(
              external_id,
              cache: { expires_in: OddsFeed::Radar::Client::DEFAULT_CACHE_TERM }
            )
            .dig('venue_summary', 'venue', 'name')
        end
      end
    end
  end
end
