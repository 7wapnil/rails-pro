# frozen_string_literal: true

module Api
  module Em
    class WalletsController < ActionController::API
      REQUEST_HANDLERS = {
        'getaccount' => 'Em::Requests::GetAccountService',
        'getbalance' => 'Em::Requests::GetBalanceService',
        'wager'      => 'Em::Requests::WagerService'
      }.freeze
      before_action :authorize_em_wallet_api

      def create
        render json: request_handler.call(params)
      end

      private

      def request_handler
        REQUEST_HANDLERS[request_param['Request'].downcase].constantize
      end

      def authorize_em_wallet_api
        return true if valid_login_and_password?

        render json: {
          'ApiVersion': '1.0',
          'Request': request_param['Request'],
          'ReturnCode': '403',
          'Message': 'Authorization failed'
        }
      end

      def request_param
        params.permit('Request')
      end

      def login_params
        params.permit('LoginName', 'Password')
      end

      def valid_login_and_password?
        login_params['LoginName'] ==
          ENV.fetch('EVERYMATRIX_WALLET_API_USERNAME') &&
          login_params['Password'] ==
            ENV.fetch('EVERYMATRIX_WALLET_API_PASSWORD')
      end
    end
  end
end
