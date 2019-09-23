# frozen_string_literal: true

module Em
  module Requests
    class BaseRequestService < ApplicationService
      def initialize(params)
        @params = params
        @session = params.permit('SessionId')['SessionId']
        @session = Em::WalletSession.find_by(id: @session)
        @wallet = @session&.wallet
        @customer = @wallet&.customer
      end

      protected

      attr_reader :params, :customer, :wallet, :session

      def common_response
        {
          'ApiVersion' => '1.0',
          'Request'    => request_name
        }
      end

      def common_success_response
        common_response.merge(
          'ReturnCode' => 0,
          'Message'    => 'Success'
        )
      end

      def user_not_found_response
        common_response.merge(
          'ReturnCode' => 103,
          'Message'    => 'User not found'
        )
      end

      def currency_code
        wallet.currency.code
      end
    end
  end
end
