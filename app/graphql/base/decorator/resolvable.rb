# frozen_string_literal: true

module Base
  module Decorator
    module Resolvable
      def call(obj, args = {}, ctx = {})
        result = super

        return result unless self.class.decorator_enabled?
        return result if self.class.pagination_enabled?

        apply_decorator(result)
      end

      protected

      def apply_decorator(object)
        return object.decorate unless object.is_a?(Enumerable)

        self.class.decorator_class.decorate_collection(object)
      end
    end
  end
end
