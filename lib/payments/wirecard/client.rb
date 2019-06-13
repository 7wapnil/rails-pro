# frozen_string_literal: true

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
        self.class.basic_auth(user_name, password)
      end

      def authorize_payment(transaction)
        route = '/api/payment/register'
        body = PaymentRequest.new(transaction).build

        Rails.logger.debug message: 'Sending WireCard authorization request',
                           route: route,
                           body: body

        self.class.post(route, body: body.to_json,
                               headers: { 'Authorization': auth_token })
      end

      private

      def user_name
        ENV['WIRECARD_USERNAME']
      end

      def password
        ENV['WIRECARD_PASSWORD']
      end

      def auth_token
        "Basic #{encrypted_credentials}"
      end

      def encrypted_credentials
        Base64.encode64("#{user_name}:#{password}")
      end
    end
  end
end
