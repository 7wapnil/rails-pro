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
          BalanceCalculationService.call(session: session).merge(
            'SessionId' => session.id,
            'Currency'  => response_currency_code
          )
        )
      end

      def response_currency_code
        denominate_currency_code(code: currency_code)
      end

      def response_real_money
        denominate_response_amount(
          code: currency_code,
          amount: wallet.real_money_balance
        )
      end

      def response_bonus_money
        denominate_response_amount(
          code: currency_code,
          amount: wallet.bonus_balance
        )
      end

      def response_balance
        denominate_response_amount(
          code: currency_code,
          amount: wallet.amount
        )
      end
    end
  end
end
