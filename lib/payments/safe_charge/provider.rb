# frozen_string_literal: true

module Payments
  module SafeCharge
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        ::Payments::SafeCharge::Deposits::RequestHandler.call(transaction)
      end

      def deposit_response_handler
        ::Payments::SafeCharge::Deposits::CallbackHandler
      end

      def payout_request_handler
        ::Payments::SafeCharge::Payouts::RequestHandler
      end
    end
  end
end