module OddsFeed
  module Radar
    module Entities
      class BaseLoader < ApplicationService
        def initialize(external_id:)
          @external_id = external_id
        end

        def call
          cache_entity if cached_entity_name.blank?

          redis_connection.disconnect!

          cached_entity_name || entity_name
        end

        private

        attr_reader :external_id

        def radar_entity_name
          raise NotImplementedError, 'Implement `radar_entity_name` method!'
        end

        def cached_entity_name
          @cached_entity_name ||= redis_connection.hget(:entities, external_id)
        end

        def redis_connection
          @redis_connection ||= Redis.new(host: ENV['REDIS_HOST'])
        end

        def cache_entity
          redis_connection.hset(:entities, external_id, entity_name)
        end

        def entity_name
          @entity_name ||= radar_entity_name
        end
      end
    end
  end
end
