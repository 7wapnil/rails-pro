# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Client
      include HTTParty

      DEPOSIT_ROUTE = '/addresses/take'
      WITHDRAW_ROUTE = '/withdrawal/crypto'

      base_uri ENV['COINSPAID_API_ENDPOINT']
      raise_on [400, 401, 403, 500]
      headers 'X-Processing-Key': ENV['COINSPAID_KEY'],
              'Accept': 'application/json'
      format :json
      debug_output $stdout

      def authorize_payment(transaction)
        self.class.headers(
          'X-Processing-Signature': payment_signature(transaction)
        )

        request = self.class.post(
          DEPOSIT_ROUTE,
          body: payment_body(transaction)
        )

        payment_address(request)
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
          currency: ::Payments::CoinsPaid::Currency::BTC_CODE,
          foreign_id: transaction.id.to_s,
          amount: transaction.amount,
          address: transaction.details['bitcoin_address']
        }.to_json
      end

      def payment_body(transaction)
        {
          currency: ::Payments::CoinsPaid::Currency::BTC_CODE,
          foreign_id: transaction.id.to_s
        }.to_json
      end

      def payout_signature(transaction)
        @payout_signature ||= Payments::CoinsPaid::SignatureService.call(
          data: payout_body(transaction)
        )
      end

      def payment_signature(transaction)
        @payment_signature ||= Payments::CoinsPaid::SignatureService.call(
          data: payment_body(transaction)
        )
      end

      def payment_address(response)
        JSON.parse(response.body).dig('data', 'address')
      end
    end
  end
end
