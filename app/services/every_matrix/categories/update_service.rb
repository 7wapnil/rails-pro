# frozen_string_literal: true

module EveryMatrix
  module Categories
    class UpdateService < ApplicationService
      def initialize(category:, params:)
        @category = category
        @params = params
      end

      def call
        trigger_categories_update if category.update(params)
      end

      private

      attr_reader :category, :params

      def trigger_categories_update
        WebSocket::Client
          .instance
          .trigger_categories_update(category)
      end
    end
  end
end
