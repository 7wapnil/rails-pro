# frozen_string_literal: true

module EntryRequests
  module Factories
    class EmRollbackPlacement < ApplicationService
      def initialize(transaction:, initiator: nil)
        @rollback = transaction
        @passed_initiator = initiator
      end

      def call
        create_entry_request!
        request_balance_update!

        entry_request
      end

      private

      attr_reader :rollback, :entry_request, :passed_initiator

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        rollback_attributes.merge(
          initiator: initiator,
          kind: EntryRequest::EM_ROLLBACK,
          mode: EntryRequest::INTERNAL
        )
      end

      def rollback_attributes
        {
          amount:   rollback.amount,
          currency: rollback.currency,
          customer: rollback.customer,
          origin:   rollback
        }
      end

      def initiator
        passed_initiator || rollback.customer
      end

      def request_balance_update!
        entry_request.update!(amount_calculations)
      end

      def amount_calculations
        BalanceCalculations::EmRollback.call(rollback: rollback)
      end
    end
  end
end
