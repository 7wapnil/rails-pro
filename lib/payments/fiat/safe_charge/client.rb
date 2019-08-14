# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class Client
        include HTTParty

        ERROR_STATUS = 'ERROR'

        base_uri ENV['SAFECHARGE_URL']
        raise_on [400, 401, 403, 500]
        headers 'Accept': 'application/json',
                'Content-Type': 'application/json'
        format :json
        debug_output $stdout

        def initialize(customer:)
          @customer = customer
        end

        def receive_user_payment_option(option_id)
          receive_user_payment_options
            .find { |item| item['userPaymentOptionId'].to_s == option_id.to_s }
            .to_h
        end

        def receive_user_payment_options
          route = '/ppp/api/v1/getUserUPOs.do'
          body = RequestBuilders::ReceiveUserPaymentOptions
                 .call(customer: customer)

          request(:post, route, body: body.to_json)
            .to_h
            .fetch('paymentMethods', [])
        end

        private

        attr_reader :customer

        def request(method, route, **options)
          response = self.class.send(method, route, options)

          return internal_server_error(response) unless response.ok?
          return error(response) if response['status'] == ERROR_STATUS

          response
        end

        def internal_server_error(response)
          Rails.logger.error(message: 'SafeCharge API error',
                             response: response.body)
          nil
        end

        def error(response)
          Rails.logger.error(message: 'SafeCharge API error',
                             response: response['reason'])
          nil
        end
      end
    end
  end
end
