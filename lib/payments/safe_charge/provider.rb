# frozen_string_literal: true

module Payments
  module SafeCharge
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        PaymentPageUrl.call(transaction)
      end

      def payment_response_handler
        ::Payments::SafeCharge::PaymentResponse
      end
    end
  end
end
