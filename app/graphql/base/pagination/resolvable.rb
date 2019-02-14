# frozen_string_literal: true

module Base
  module Pagination
    module Resolvable
      def call(obj, args = {}, ctx = {})
        pagy, data = pagy(super, page: args[:page], items: args[:per_page])

        Pagination::ObjectBuilder.call(collection: data, pagy: pagy)
      end
    end
  end
end
