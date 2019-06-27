# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Client
      include HTTParty

      DEPOSIT_ROUTE = '/addresses/take'

      base_uri ENV['COINSPAID_API_ENDPOINT']
      raise_on [400, 401, 403, 500]
      headers 'X-Processing-Key': ENV['COINSPAID_KEY'],
              'Accept': 'application/json'
      format :json
      debug_output $stdout

      def authorize_payment(transaction)
        self.class.headers('X-Processing-Signature': signature(transaction))

        request = self.class.post(DEPOSIT_ROUTE, body: body(transaction))

        payment_address(request)
      end

      private

      def body(transaction)
        {
          currency: ::Payments::CoinsPaid::Currency::BTC_CODE,
          foreign_id: transaction.id.to_s
        }.to_json
      end

      def signature(transaction)
        @signature ||= Payments::CoinsPaid::SignatureService.call(
          data: body(transaction)
        )
      end

      def payment_address(response)
        JSON.parse(response.body).dig('data', 'address')
      end
    end
  end
end
