# frozen_string_literal: true

module EveryMatrix
  module Requests
    class GetBalanceService < SessionRequestService
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
          'Balance'    => wallet.real_money_balance,
          'Currency'   => currency_code,
          'BonusMoney' => 0.0,
          'RealMoney'  => wallet.real_money_balance
        )
      end
    end
  end
end
