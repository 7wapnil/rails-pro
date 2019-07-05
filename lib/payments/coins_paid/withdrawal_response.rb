# frozen_string_literal: true

module Payments
  module CoinsPaid
    class WithdrawalResponse < ::Payments::WithdrawalResponse
      include Statuses

      def initialize(response)
        @response = response
      end

      def call
        return succeeded! if confirmed?

        cancelled!(error_message)
      end

      private

      def confirmed?
        response['status'] == CONFIRMED
      end

      def error_message
        response['error']
      end

      def request_id
        response['foreign_id']
      end

      def transactions_id
        response.dig('transactions', 0, 'txid')
      end
    end
  end
end
