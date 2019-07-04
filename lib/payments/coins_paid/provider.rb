# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        client.authorize_payment(transaction)
      end

      def deposit_response_handler
        ::Payments::CoinsPaid::DepositResponse
      end

      private

      def client
        @client ||= Client.new
      end
    end
  end
end
