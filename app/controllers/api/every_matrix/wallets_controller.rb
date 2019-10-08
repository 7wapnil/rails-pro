# frozen_string_literal: true

module Api
  module EveryMatrix
    class WalletsController < ActionController::API
      REQUEST_HANDLERS = {
        'getaccount' => 'EveryMatrix::Requests::GetAccountService',
        'getbalance' => 'EveryMatrix::Requests::GetBalanceService',
        'wager'      => 'EveryMatrix::Requests::WagerService',
        'result'     => 'EveryMatrix::Requests::ResultService',
        'rollback'   => 'EveryMatrix::Requests::RollbackService',
        'gettransactionstatus' =>
          'EveryMatrix::Requests::GetTransactionStatusService'
      }.freeze

      before_action :authorize_wallet_api

      def create
        Rails.logger.info 'PARAMS:'
        Rails.logger.info params
        Rails.logger.info

        response_json = request_handler.call(params)

        Rails.logger.info 'RESPONSE'
        Rails.logger.info response_json
        Rails.logger.info

        render json: response_json
      end

      private

      def request_handler
        REQUEST_HANDLERS[request_param['Request'].downcase].constantize
      end

      def authorize_wallet_api
        return true if valid_login_and_password?

        render json: {
          'ApiVersion' => '1.0',
          'Request'    => request_param['Request'],
          'ReturnCode' => 103,
          'Message'    => 'User not found'
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
