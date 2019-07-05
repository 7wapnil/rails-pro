# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        client.authorize_payment(transaction)
      end

      def process_payout(transaction)
        client.authorize_payout(transaction)
      end

      def deposit_response_handler
        ::Payments::CoinsPaid::DepositResponse
      end

      def response_handler
        ::Payments::CoinsPaid::ResponseHandler
      end

      private

      def client
        @client ||= Client.new
      end
    end
  end
end
