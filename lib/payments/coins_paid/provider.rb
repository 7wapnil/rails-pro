# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        ::CryptoAddresses::GetOrCreate.call(transaction)
      end

      def callback_handler
        ::Payments::CoinsPaid::CallbackHandler
      end

      def payout_request_handler
        ::Payments::CoinsPaid::Payouts::RequestHandler
      end
    end
  end
end
