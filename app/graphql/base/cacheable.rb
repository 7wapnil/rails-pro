# frozen_string_literal: true

module Base
  module Cacheable
    extend ActiveSupport::Concern

    EVENT_UPCOMING_CONTEXT_CACHE_TTL = 5.seconds
    EVENT_LIVE_CONTEXT_CACHE_TTL     = 2.seconds

    class_methods do
      attr_reader :cache

      def cache_for(time = nil)
        @cache = time
      end
    end

    included do
      prepend Cache::Resolvable
    end
  end
end
