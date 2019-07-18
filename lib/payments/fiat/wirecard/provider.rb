# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      class Provider < ::Payments::Fiat::Provider
        def payment_page_url
          ::Payments::Fiat::Wirecard::Deposits::RequestHandler
            .call(transaction: transaction)
        end

        def payout_request_handler
          ::Payments::Fiat::Wirecard::Payouts::RequestHandler
        end
      end
    end
  end
end
