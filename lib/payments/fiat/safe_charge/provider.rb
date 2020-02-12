# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class Provider < ::Payments::Fiat::Provider
        def payment_page_url
          ::Payments::Fiat::SafeCharge::Deposits::RequestHandler
            .call(transaction)
        end

        protected

        def payout_request_handler
          ::Payments::Fiat::SafeCharge::Payouts::RequestHandler
        end
      end
    end
  end
end
