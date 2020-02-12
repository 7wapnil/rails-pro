# frozen_string_literal: true

module Payments
  module Fiat
    class Provider < ::Payments::Provider
      def validate_customer
        customer_validation_handler.call(transaction)
      end

      def payment_page_url
        raise ::NotImplementedError
      end

      def process_payout
        payout_request_handler.call(transaction)
      end

      protected

      def customer_validation_handler
        raise NotImplementedError
      end

      def payout_request_handler
        raise NotImplementedError
      end
    end
  end
end
