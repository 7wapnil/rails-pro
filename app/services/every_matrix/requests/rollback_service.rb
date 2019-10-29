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
    end
  end
end
