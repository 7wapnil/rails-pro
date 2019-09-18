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

          raise(::SafeCharge::ApiError, response.body) unless response.ok?

          return response unless invalid_response?(response)

          raise ::SafeCharge::ApiError, response['reason']
        rescue ::SafeCharge::ApiError => e
          Rails.logger.error(error_object: e, message: e.message)

          nil
        end

        def invalid_response?(response)
          response['status'] == ERROR_STATUS
        end
      end
    end
  end
end
