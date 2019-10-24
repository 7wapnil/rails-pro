# frozen_string_literal: true

module Base
  module Cache
    module Resolvable
      def call(obj, args = {}, ctx = {})
        ctx['cache'] = duration(args) if cacheable?

        super
      end

      protected

      def cacheable?
        self.class.cache.present?
      end

      def duration(args)
        return self.class.cache if duration_cache_arg?

        method(self.class.cache).call(args)
      end

      def duration_cache_arg?
        self.class.cache.is_a?(ActiveSupport::Duration)
      end
    end
  end
end
