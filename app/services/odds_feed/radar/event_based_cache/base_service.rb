# frozen_string_literal: true

module OddsFeed
  module Radar
    module EventBasedCache
      class BaseService < ApplicationService
        def initialize(event:)
          @event = event
        end

        protected

        attr_reader :event

        def competitors_from_payload
          event
            .payload
            .to_h
            .dig('competitors', 'competitor')
        end
      end
    end
  end
end
