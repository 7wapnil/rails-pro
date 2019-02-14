# frozen_string_literal: true

module Base
  module Pagination
    class ObjectBuilder < ApplicationService
      def initialize(data:, pagy:)
        @data = data
        @pagy = pagy
      end

      def call
        Pagination::PaginatedObject.new(pagination_info, data)
      end

      private

      attr_reader :data, :pagy

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
