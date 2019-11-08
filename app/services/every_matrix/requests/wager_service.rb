# frozen_string_literal: true

module EveryMatrix
  module Requests
    class WagerService < TransactionService
      private

      def request_name
        'Wager'
      end

      def transaction_class
        EveryMatrix::Wager
      end

      def placement_service
        EntryRequests::Factories::EveryMatrix::WagerPlacement
      end

      def insufficient_funds?
        wallet && (amount > wallet.amount)
      end

      def valid_request?
        !insufficient_funds?
      end

      def validation_failed
        insufficient_funds_response
      end

      def insufficient_funds_response
        common_response.merge(
          'ReturnCode' => 104,
          'Message'    => 'Insufficient funds'
        )
      end

      def entry_creation_failed
        common_response.merge(
          'ReturnCode' => 112,
          'Message'    => 'MaxStakeLimitExceeded'
        )
      end

      def post_process
        WagerSettlementService.call(transaction)
      end

      def post_process_failed; end
    end
  end
end
