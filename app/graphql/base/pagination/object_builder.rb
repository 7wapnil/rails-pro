# frozen_string_literal: true

module Base
  module Pagination
    class ObjectBuilder < ApplicationService
      def initialize(collection:, pagy:, extra_fields: {})
        @collection = collection
        @pagy = pagy
        @extra_fields = extra_fields
      end

      def call
        return build_paginated_object if extra_fields.blank?

        OpenStruct.new(**build_paginated_object.to_h, **extra_fields)
      end

      private

      attr_reader :collection, :pagy, :extra_fields

      def build_paginated_object
        Pagination::PaginatedObject.new(pagination_info, collection)
      end

      def pagination_info
        Pagination::Info.new(*pagination_info_values)
      end

      def pagination_info_values
        pagy
          .instance_values
          .symbolize_keys
          .slice(*Pagination::Info.members)
          .values
      end
    end
  end
end
