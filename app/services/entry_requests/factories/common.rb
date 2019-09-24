# frozen_string_literal: true

module EntryRequests
  module Factories
    class Common < ApplicationService
      def initialize(origin:, **attributes)
        @origin = origin
        @attributes = attributes
      end

      def call
        create_entry_request!

        entry_request
      end

      private

      attr_reader :entry_request, :origin, :attributes

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        return attributes unless origin

        attributes
          .merge(origin_attributes)
          .merge(balance_calculations)
      end

      def origin_attributes
        {
          currency: origin.currency,
          initiator: origin.customer,
          customer: origin.customer,
          origin: origin
        }
      end

      def balance_calculations
        BalanceCalculations::BetCompensation.call(
          bet: origin,
          amount: requested_total_amount
        )
      end

      def requested_total_amount
        attributes[:amount] || 0
      end
    end
  end
end
