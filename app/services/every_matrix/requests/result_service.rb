# frozen_string_literal: true

module EveryMatrix
  module Requests
    class ResultService < TransactionService
      def post_process_service
        ResultSettlementService
      end

      private

      def request_name
        'Result'
      end

      def transaction_class
        EveryMatrix::Result
      end

      def placement_service
        EntryRequests::Factories::EveryMatrix::ResultPlacement
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
