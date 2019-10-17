# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class Client
        include HTTParty

        CONTENT_TYPE = 'application/json; charset=utf8'

        base_uri ENV['SAFECHARGE_URL']
        raise_on [400, 401, 403, 500]
        headers 'Accept': 'application/json',
                'Content-Type': CONTENT_TYPE
        format :json
        debug_output $stdout

        def receive_user_payment_options(options_params)
          route = '/ppp/api/v1/getUserUPOs.do'

          request(:post, route, body: options_params.to_json,
                                headers: { 'Content-Type' => CONTENT_TYPE })
        end

        def receive_deposit_redirect_url(deposit_params)
          route = '/ppp/api/v1/getPaymentPageUrl.do'

          request(:post, route, body: deposit_params.to_json,
                                headers: { 'Content-Type' => CONTENT_TYPE })
        end

        def authorize_payout(payout_params)
          route = '/ppp/api/withdrawal/submitRequest.do'

          request(:post, route, body: payout_params.to_json,
                                headers: { 'Content-Type' => CONTENT_TYPE })
        end

        def approve_payout(approve_params)
          route = '/ppp/api/withdrawal/approveRequest.do'

          request(:post, route, body: approve_params.to_json,
                                headers: { 'Content-Type' => CONTENT_TYPE })
        end

        def receive_order_details(order_params)
          route = '/ppp/api/withdrawal/getOrders.do'

          request(:post, route, body: order_params.to_json,
                                headers: { 'Content-Type' => CONTENT_TYPE })
        end

        private

        attr_reader :customer

        def request(method, route, **options)
          self.class.send(method, route, options)
        rescue HTTParty::Error => e
          e.response
        end
      end
    end
  end
end
