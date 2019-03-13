# frozen_string_literal: true

module OddsFeed
  module Radar
    module EventBasedCache
      class Collector < BaseService
        def call
          {
            **competitors_cache_data
          }
        end

        private

        def competitors_cache_data
          Array
            .wrap(competitors_from_payload)
            .reduce({}, &method(:collect_competitor_cache_data))
        end

        def collect_competitor_cache_data(data, attributes)
          data.deep_merge(
            map_competitor_cache_data(attributes['id'])
          )
        end

        def map_competitor_cache_data(external_id)
          Entities::CompetitorLoader.call(
            external_id: external_id,
            collect_only: true
          )
        end
      end
    end
  end
end
