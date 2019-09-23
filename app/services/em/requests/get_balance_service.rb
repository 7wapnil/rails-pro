# frozen_string_literal: true

module Em
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

      def bonus_balance
        wallet.balances.bonus.first
      end

      def real_money_balance
        wallet.balances.real_money.first
      end

      def success_response
        common_success_response.merge(
          'SessionId'  => session.id,
          'Balance'    => wallet.amount,
          'Currency'   => currency_code,
          'BonusMoney' => bonus_balance&.amount || 0.0,
          'RealMoney'  => real_money_balance&.amount || 0.0
        )
      end
    end
  end
end
