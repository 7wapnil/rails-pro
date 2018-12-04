module OddsFeed
  module Radar
    module Entities
      class VenueLoader < BaseLoader
        private

        def radar_entity_name
          OddsFeed::Radar::Client
            .new
            .venue_summary(external_id)
            .dig('venue_summary', 'venue', 'name')
        end
      end
    end
  end
end
