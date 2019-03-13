# frozen_string_literal: true

module OddsFeed
  module Radar
    module EventBasedCache
      class Writer < BaseService
        def call
          cache_competitors
        end

        private

        def cache_competitors
          Array
            .wrap(competitors_from_payload)
            .each { |attributes| cache_competitor(attributes['id']) }
        end

        def cache_competitor(external_id)
          Entities::CompetitorLoader.call(external_id: external_id)
        end
      end
    end
  end
end
