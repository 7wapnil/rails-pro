# frozen_string_literal: true

module Payments
  module Wirecard
    class Client
      include HTTParty

      DEPOSIT_URL = ENV['WIRECARD_DEPOSIT_API_ENDPOINT']
      PAYOUT_URL = ENV['WIRECARD_PAYOUT_API_ENDPOINT']

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
        body = ::Payments::Wirecard::Deposits::RequestBuilder.call(transaction)

        Rails.logger.debug message: 'Sending WireCard authorization request',
                           route: route,
                           body: body

        self.class.post(route, base_uri: DEPOSIT_URL,
                               body: body.to_json,
                               headers: { 'Authorization': auth_token })
      end

      def authorize_payout(transaction)
        route = '/engine/rest/payments'
        body = ::Payments::Wirecard::Payouts::RequestBuilder
               .call(transaction)

        self.class.post(route,
                        base_uri: PAYOUT_URL,
                        body: body,
                        headers: xml_header)
      rescue HTTParty::Error => e
        e.response
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

      def xml_header
        {
          'Authorization': auth_token,
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
        }
      end
    end
  end
end
