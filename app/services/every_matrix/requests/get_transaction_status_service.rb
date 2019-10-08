# frozen_string_literal: true

module EveryMatrix
  module Requests
    class GetTransactionStatusService < BaseRequestService
      def call
        find_transaction

        return notexists_response unless transaction

        processed_response
      end

      protected

      def request_name
        'GetTransactionStatus'
      end

      private

      attr_accessor :transaction, :transaction_id

      def find_transaction
        @transaction_id = params.permit('TransactionId')['TransactionId']

        @transaction =
          EveryMatrix::Transaction.find_by(transaction_id: @transaction_id)
      end

      def transaction_response(status:)
        common_success_response.merge(
          'TransactionId' => transaction_id.to_i,
          'TransactionStatus' => status
        )
      end

      def notexists_response
        transaction_response(status: 'Notexists')
      end

      def processed_response
        transaction_response(status: 'Processed')
      end
    end
  end
end
