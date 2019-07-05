# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        client.authorize_payment(transaction)
      end

      def perform_payout_api_call(transaction)
        client.authorize_payout(transaction)
      end

      def response_handler
        ::Payments::CoinsPaid::ResponseHandler
      end

      def payout_response_handler
        ::Payments::CoinsPaid::PayoutResponseHandler
      end

      private

      def client
        @client ||= Client.new
      end
    end
  end
end
