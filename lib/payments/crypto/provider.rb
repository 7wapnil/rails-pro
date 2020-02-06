# frozen_string_literal: true

module Payments
  module Crypto
    class Provider < ::Payments::Provider
      def initialize(transaction)
        @transaction = transaction
      end

      def validate_customer
        customer_validation_handler.call(transaction)
      end

      def receive_deposit_address
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
