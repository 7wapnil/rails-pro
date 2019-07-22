# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      class Client
        include HTTParty

        DEPOSIT_ROUTE = '/addresses/take'
        WITHDRAW_ROUTE = '/withdrawal/crypto'
        M_BTC_MULTIPLIER = 1000

        base_uri ENV['COINSPAID_API_ENDPOINT']
        raise_on [400, 401, 403, 500]
        headers 'X-Processing-Key': ENV['COINSPAID_KEY'],
                'Accept': 'application/json'
        format :json
        debug_output $stdout

        def generate_address(customer)
          self.class.headers(
            'X-Processing-Signature': address_request_signature(customer)
          )

          request = self.class.post(
            DEPOSIT_ROUTE,
            body: address_request_body(customer)
          )

          crypto_address(request)
        end

        def authorize_payout(transaction)
          self.class.headers(
            'X-Processing-Signature': payout_signature(transaction)
          )
          self.class.post(
            WITHDRAW_ROUTE,
            body: payout_body(transaction)
          )
        rescue HTTParty::Error => e
          e.response
        end

        private

        def payout_body(transaction)
          {
            currency: ::Payments::Crypto::CoinsPaid::Currency::BTC_CODE,
            foreign_id: transaction.id.to_s,
            amount: transaction.amount / M_BTC_MULTIPLIER,
            address: transaction.details['address']
          }.to_json
        end

        def address_request_body(customer)
          {
            currency: ::Payments::Crypto::CoinsPaid::Currency::BTC_CODE,
            foreign_id: customer.id.to_s
          }.to_json
        end

        def payout_signature(transaction)
          @payout_signature ||=
            ::Payments::Crypto::CoinsPaid::SignatureService.call(
              data: payout_body(transaction)
            )
        end

        def address_request_signature(customer)
          @address_request_signature ||=
            ::Payments::Crypto::CoinsPaid::SignatureService.call(
              data: address_request_body(customer)
            )
        end

        def crypto_address(response)
          JSON.parse(response.body).dig('data', 'address')
        end
      end
    end
  end
end
