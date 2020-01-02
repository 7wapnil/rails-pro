# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      class Provider < ::Payments::Fiat::Provider
        def payment_page_url
          ::Payments::Fiat::Wirecard::Deposits::RequestHandler
            .call(transaction: transaction)
        end

        protected

        def customer_validation_handler
          ::Payments::Fiat::Wirecard::Validations::CustomerValidationHandler
        end

        def payout_request_handler
          ::Payments::Fiat::Wirecard::Payouts::RequestHandler
        end
      end
    end
  end
end
