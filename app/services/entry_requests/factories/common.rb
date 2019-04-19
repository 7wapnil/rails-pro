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
        create_balance_requests!

        entry_request
      end

      private

      attr_reader :entry_request, :origin, :attributes

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

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

      def create_balance_requests!
        BalanceRequestBuilders::Common.call(entry_request, amount_calculations)
      end

      def amount_calculations
        BalanceCalculations::BetCompensation.call(entry_request: entry_request)
      end
    end
  end
end
