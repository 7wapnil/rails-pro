# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      class Provider < ::Payments::Crypto::Provider
        def receive_deposit_address
          ::Payments::Crypto::CoinsPaid::Deposits::RequestHandler
            .call(transaction)
        end

        protected

        def payout_request_handler
          ::Payments::Crypto::CoinsPaid::Payouts::RequestHandler
        end
      end
    end
  end
end
