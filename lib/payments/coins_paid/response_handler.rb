# frozen_string_literal: true

module Payments
  module CoinsPaid
    class ResponseHandler < ::ApplicationService
      DEPOSIT = 'deposit'
      WITHDRAWAL = 'withdrawal'

      def initialize(request)
        @request = request
      end

      def call
        case payment_type
        when DEPOSIT
          ::Payments::CoinsPaid::DepositResponseHandler.call(response)
        when WITHDRAWAL
          ::Payments::CoinsPaid::WithdrawalResponseHandler.call(response)
        end
      end

      private

      attr_reader :request

      def response
        @response ||= JSON.parse(request.body.string)
      end

      def payment_type
        response['type']
      end
    end
  end
end
