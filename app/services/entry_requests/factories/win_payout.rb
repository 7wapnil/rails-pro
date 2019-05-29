# frozen_string_literal: true

module EntryRequests
  module Factories
    class WinPayout < ApplicationService
      def initialize(origin:, **attributes)
        @bet = origin
        @attributes = attributes
      end

      def call
        create_entry_request!
        create_balance_requests!

        entry_request
      end

      private

      attr_reader :bet, :entry_request, :attributes

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        attributes.merge(origin_attributes)
      end

      def origin_attributes
        return {} unless bet

        {
          currency: bet.currency,
          initiator: bet.customer,
          customer: bet.customer,
          origin: bet
        }
      end

      def create_balance_requests!
        BalanceRequestBuilders::WinPayout
          .call(entry_request, amount_calculations)
      end

      def amount_calculations
        BalanceCalculations::BetCompensation.call(entry_request: entry_request)
      end
    end
  end
end
