# frozen_string_literal: true

module Base
  module Pagination
    module Resolvable
      def call(obj, args = {}, ctx = {})
        pagy, data = pagy(super, page: args[:page], items: args[:perPage])

        data = apply_decorator(data) if self.class.decorator_enabled?

        Pagination::ObjectBuilder.call(
          collection: data,
          pagy: pagy,
          extra_fields: extend_pagination_result(args)
        )
      end
    end
  end
end
