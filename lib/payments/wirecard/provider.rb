# frozen_string_literal: true

module Payments
  module Wirecard
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        ::Payments::Wirecard::Deposits::RequestHandler
          .call(transaction: transaction)
      end

      def deposit_response_handler
        ::Payments::Wirecard::Deposits::CallbackHandler
      end

      def payout_request_handler
        ::Payments::Wirecard::Payouts::RequestHandler
      end
    end
  end
end
