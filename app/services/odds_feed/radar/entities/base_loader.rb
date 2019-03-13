# frozen_string_literal: true

module OddsFeed
  module Radar
    module Entities
      class BaseLoader < ApplicationService
        CACHE_TERM = 1.week

        def initialize(external_id:, **options)
          @external_id = external_id
          @options = options
        end

        def call
          return collect_data if options[:collect_only]

          cached_entity_name || cache_entity_name
        end

        protected

        attr_reader :external_id, :options

        def cache_additional_entries; end

        def radar_entity_name
          raise NotImplementedError, 'Implement `radar_entity_name` method!'
        end

        def collect_data
          raise NotImplementedError, 'Implement `collect_data` method!'
        end

        def entity_cache_key(id)
          "entity-names:#{id}"
        end

        def entity_name
          @entity_name ||= radar_entity_name
        end

        private

        def cached_entity_name
          Rails.cache.read(entity_cache_key(external_id))
        end

        def cache_entity_name
          Rails.cache.write(entity_cache_key(external_id),
                            entity_name,
                            cache: { expires_in: CACHE_TERM })

          cache_additional_entries

          entity_name
        end
      end
    end
  end
end
