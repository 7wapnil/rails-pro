# frozen_string_literal: true

module EveryMatrix
  module Requests
    class GetBalanceService < SessionRequestService
      include CurrencyDenomination

      def call
        return user_not_found_response unless customer

        success_response
      end

      protected

      def request_name
        'GetBalance'
      end

      private

      def success_response
        common_success_response.merge(
          'SessionId'  => session.id,
          'Balance'    => response_balance_amount,
          'Currency'   => response_currency_code,
          'BonusMoney' => 0.0,
          'RealMoney'  => response_balance_amount
        )
      end

      def response_currency_code
        denominate_currency_code(code: currency_code)
      end

      def response_balance_amount
        denominate_response_amount(
          code: currency_code,
          amount: wallet.real_money_balance
        )
      end
    end
  end
end
