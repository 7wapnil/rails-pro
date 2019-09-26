# frozen_string_literal: true

module Em
  module Requests
    class RollbackService < TransactionService
      protected

      def request_name
        'Rollback'
      end

      def transaction_class
        Em::Result
      end

      def placement_service
        EntryRequests::Factories::EmRollbackPlacement
      end
    end
  end
end
