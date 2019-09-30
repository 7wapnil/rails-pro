# frozen_string_literal: true

module EveryMatrix
  module Requests
    class ResultService < TransactionService
      protected

      def request_name
        'Result'
      end

      def transaction_class
        EveryMatrix::Result
      end

      def placement_service
        EntryRequests::Factories::EmResultPlacement
      end
    end
  end
end
