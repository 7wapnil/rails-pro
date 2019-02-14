# frozen_string_literal: true

module EntryRequests
  module Factories
    class Common < ApplicationService
      def initialize(origin:, **attributes)
        @origin = origin
        @attributes = attributes
      end

      def call
        EntryRequest.create!(entry_request_attributes)
      end

      private

      attr_reader :origin, :attributes

      def entry_request_attributes
        attributes.merge(origin_attributes)
      end

      def origin_attributes
        return {} unless origin

        {
          currency: origin.currency,
          initiator: origin.customer,
          customer: origin.customer,
          origin: origin
        }
      end
    end
  end
end
