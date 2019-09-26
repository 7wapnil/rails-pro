# frozen_string_literal: true

module EntryRequests
  module Factories
    class EmWagerPlacement < ApplicationService
      def initialize(transaction:, initiator: nil)
        @wager = transaction
        @passed_initiator = initiator
      end

      def call
        create_entry_request!
        request_balance_update!

        entry_request
      end

      private

      attr_reader :wager, :entry_request, :passed_initiator

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        wager_attributes.merge(
          initiator: initiator,
          kind: EntryRequest::EM_WAGER,
          mode: EntryRequest::INTERNAL
        )
      end

      def wager_attributes
        {
          amount:   wager.amount,
          currency: wager.currency,
          customer: wager.customer,
          origin:   wager
        }
      end

      def initiator
        passed_initiator || wager.customer
      end

      def request_balance_update!
        entry_request.update!(amount_calculations)
      end

      def amount_calculations
        BalanceCalculations::EmWager.call(wager: wager)
      end
    end
  end
end
