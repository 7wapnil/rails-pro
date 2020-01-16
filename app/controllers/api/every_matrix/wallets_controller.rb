# frozen_string_literal: true

module Api
  module EveryMatrix
    class WalletsController < ActionController::API
      FILTERED_PARAMS = %w[Password FirstName LastName].freeze

      include ::EveryMatrix::Requests::ErrorCodes

      REQUEST_HANDLERS = {
        'getaccount' => 'EveryMatrix::Requests::GetAccountService',
        'getbalance' => 'EveryMatrix::Requests::GetBalanceService',
        'wager' => 'EveryMatrix::Requests::WagerService',
        'result' => 'EveryMatrix::Requests::ResultService',
        'rollback' => 'EveryMatrix::Requests::RollbackService',
        'gettransactionstatus' =>
          'EveryMatrix::Requests::GetTransactionStatusService'
      }.freeze

      before_action :authorize_wallet_api

      def create
        response_json = request_handler.call(params)

        log_request(:info, params, response_json)

        render json: response_json
      end

      private

      def request_handler
        REQUEST_HANDLERS[request_name].constantize
      end

      def request_name
        request_param['Request'].downcase
      end

      def authorize_wallet_api
        return true if valid_login_and_password?

        render json: {
          'ApiVersion' => '1.0',
          'Request'    => request_param['Request'],
          'ReturnCode' => USER_NOT_FOUND_CODE,
          'Message'    => USER_NOT_FOUND_MESSAGE
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
          ENV['EVERYMATRIX_WALLET_API_USERNAME'] &&
          login_params['Password'] ==
            ENV['EVERYMATRIX_WALLET_API_PASSWORD']
      end

      def log_request(level, params, response_json)
        Rails.logger.send(level,
                          message: 'EveryMatrix Wallet API request',
                          request_name: request_name,
                          params: params.except(FILTERED_PARAMS),
                          response: response_json)
      end
    end
  end
end
