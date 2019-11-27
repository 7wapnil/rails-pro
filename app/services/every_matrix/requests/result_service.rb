# frozen_string_literal: true

module EveryMatrix
  module Requests
    class ResultService < TransactionService
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
          'ReturnCode' => 112,
          'Message'    => transaction.entry_request.result['message']
        )
      end
    end
  end
end
