module Payments
  module Wirecard
    class Client
      include HTTParty

      base_uri ENV['WIRECARD_API_ENDPOINT']
      raise_on [400, 401, 403, 500]
      headers 'Accept': 'application/json',
              'Content-Type': 'application/json'
      format :json
      debug_output $stdout

      def initialize
        self.class.basic_auth(
          # ENV['WIRECARD_USERNAME'],
          # ENV['WIRECARD_PASSWORD']
          '70000-APIDEMO-CARD',
          'ohysS0-dvfMx'
        )
      end

      def authorize_payment(transaction)
        route = '/api/payment/register'
        body = PaymentRequest.new(transaction).build.to_json

        Rails.logger.debug message: 'Sending WireCard authorization request',
                           route: route,
                           body: body

        self.class.post(route, body: body)
      end
    end
  end
end
