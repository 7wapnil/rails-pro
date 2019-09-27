# frozen_string_literal: true

module EntryRequests
  module Factories
    class EmResultPlacement < ApplicationService
      def initialize(transaction:, initiator: nil)
        @result = transaction
        @passed_initiator = initiator
      end

      def call
        create_entry_request!
        request_balance_update!

        entry_request
      end

      private

      attr_reader :result, :entry_request, :passed_initiator

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        result_attributes.merge(
          initiator: initiator,
          kind: EntryRequest::EM_RESULT,
          mode: EntryRequest::INTERNAL
        )
      end

      def result_attributes
        {
          amount:      result.amount,
          currency:    result.currency,
          customer:    result.customer,
          origin:      result,
          external_id: result.transaction_id
        }
      end

      def initiator
        passed_initiator || result.customer
      end

      def request_balance_update!
        entry_request.update!(amount_calculations)
      end

      def amount_calculations
        BalanceCalculations::EmResult.call(result: result)
      end
    end
  end
end
