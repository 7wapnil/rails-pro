# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Provider < ::Payments::BaseProvider
      # TODO: implement Coinspaid functionality
      def payment_page_url(_transaction)
        '#'
      end

      def payment_response_handler
        ::Payments::SafeCharge::PaymentResponse
      end
    end
  end
end
