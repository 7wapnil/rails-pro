# frozen_string_literal: true

module EveryMatrix
  module Requests
    class SessionRequestService < BaseRequestService
      def initialize(params)
        super

        @session = params.permit('SessionId')['SessionId']
        @session = EveryMatrix::WalletSession.find_by(id: @session)
        @wallet = @session&.wallet
        @customer = @wallet&.customer
      end

      protected

      attr_reader :customer, :wallet, :session

      def user_not_found_response
        common_response.merge(
          'ReturnCode' => USER_NOT_FOUND_CODE,
          'Message'    => USER_NOT_FOUND_MESAGE
        )
      end

      def currency_code
        wallet&.currency&.code
      end
    end
  end
end
