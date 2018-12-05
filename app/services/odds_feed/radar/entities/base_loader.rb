module OddsFeed
  module Radar
    module Entities
      class BaseLoader < ApplicationService
        def initialize(external_id:)
          @external_id = external_id
        end

        def call
          cached_entity_name || cache_entity_name
        end

        private

        attr_reader :external_id

        def cached_entity_name
          Rails.cache.read("entity-names:#{external_id}")
        end

        def cache_entity_name
          Rails.cache.write("entity-names:#{external_id}", entity_name)

          entity_name
        end

        def entity_name
          @entity_name ||= radar_entity_name
        end

        def radar_entity_name
          raise NotImplementedError, 'Implement `radar_entity_name` method!'
        end
      end
    end
  end
end
