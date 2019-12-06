# frozen_string_literal: true

module EveryMatrix
  module Requests
    class RollbackService < TransactionService
      private

      def request_name
        'Rollback'
      end

      def transaction_class
        EveryMatrix::Result
      end

      def placement_service
        EntryRequests::Factories::EveryMatrix::RollbackPlacement
      end

      def entry_creation_failed
        common_response.merge(
          'ReturnCode' => MAX_STAKE_LIMIT_EXCEEDED_CODE,
          'Message'    => transaction.entry_request.result['message']
        )
      end
    end
  end
end
