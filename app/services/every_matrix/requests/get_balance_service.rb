# frozen_string_literal: true

module EveryMatrix
  module Requests
    class GetBalanceService < BaseRequestService
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
          'Balance'    => wallet.amount,
          'Currency'   => currency_code,
          'BonusMoney' => wallet.bonus_balance || 0.0,
          'RealMoney'  => wallet.real_money_balance || 0.0
        )
      end
    end
  end
end
