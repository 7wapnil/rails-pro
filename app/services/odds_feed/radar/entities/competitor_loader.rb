module OddsFeed
  module Radar
    module Entities
      class CompetitorLoader < BaseLoader
        NAME_SEPARATOR = ', '.freeze

        private

        def radar_entity_name
          OddsFeed::Radar::Client
            .new
            .competitor_profile(external_id)
            .dig('competitor_profile', 'competitor', 'name')
            .split(NAME_SEPARATOR)
            .reverse.join(' ')
        end
      end
    end
  end
end