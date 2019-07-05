# frozen_string_literal: true

module Payments
  module CoinsPaid
    class ResponseHandler < ::ApplicationService
      DEPOSIT = 'deposit'
      WITHDRAWAL = 'withdrawal'

      def initialize(request)
        @response = JSON.parse(request.body.string)
      end

      def call
        case payment_type
        when DEPOSIT
          ::Payments::CoinsPaid::DepositResponse.call(response)
        when WITHDRAWAL
          ::Payments::CoinsPaid::WithdrawalResponse.call(response)
        end
      end

      private

      attr_reader :response

      def payment_type
        response['type']
      end
    end
  end
end
