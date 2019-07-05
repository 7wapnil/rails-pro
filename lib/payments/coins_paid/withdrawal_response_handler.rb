# frozen_string_literal: true

module Payments
  module CoinsPaid
    class WithdrawalResponseHandler < ::Payments::WithdrawalResponseHandler
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
        response.dig('transactions', 0, 'id')
      end
    end
  end
end
