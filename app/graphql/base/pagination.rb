# frozen_string_literal: true

module Base
  module Pagination
    extend ActiveSupport::Concern

    FIRST_PAGE = Pagy::VARS[:page]
    DEFAULT_ITEMS_COUNT = Pagy::VARS[:items]

    class_methods do
      def type(premade_type = nil, &block)
        @type ||= define_pagination_object_type(premade_type, &block)
      end

      private

      def define_pagination_object_type(type, &block)
        name = self.name.delete('::')

        GraphQL::ObjectType.define do
          name "#{name}Pagination"

          field :pagination, !Types::PaginationType
          field :collection, type

          instance_eval(&block) if block
        end
      end
    end

    included do
      include Pagy::Backend
      prepend Pagination::Resolvable

      argument :page, types.Int, 'Page number', default_value: FIRST_PAGE
      argument :perPage, types.Int, 'Items per page',
               default_value: DEFAULT_ITEMS_COUNT

      protected

      def extend_pagination_result(_args); end
    end
  end
end
