# frozen_string_literal: true

module Em
  module Requests
    class ResultService < TransactionService
      protected

      def request_name
        'Result'
      end

      def transaction_class
        Em::Result
      end

      def placement_service
        EntryRequests::Factories::EmResultPlacement
      end
    end
  end
end
