# frozen_string_literal: true

module EveryMatrix
  module Requests
    class BalanceCalculationService < ApplicationService
      include CurrencyDenomination

      def initialize(session:, balance_only: false)
        @session = session
        @balance_only = balance_only
      end

      def call
        wallet.reload
        balance_response = {
          'Balance'   => calculated_balance,
          'Currency'  => calculated_currency
        }

        return balance_response if balance_only

        balance_response.merge(
          'RealMoney'  => calculated_real_money,
          'BonusMoney' => calculated_bonus_money
        )
      end

      private

      attr_reader :session, :balance_only

      delegate :wallet, to: :session
      delegate :amount, :real_money_balance, :bonus_balance,
               :currency, :customer_bonus,
               to: :wallet
      delegate :code, to: :currency, prefix: true

      def casino_bonus?
        customer_bonus&.active? && customer_bonus&.casino?
      end

      def calculated_balance
        denominate_response_amount(
          code: currency_code,
          amount: (casino_bonus? ? amount : real_money_balance)
        )
      end

      def calculated_real_money
        denominate_response_amount(
          code: currency_code,
          amount: real_money_balance
        )
      end

      def calculated_bonus_money
        denominate_response_amount(
          code: currency_code,
          amount: (casino_bonus? ? bonus_balance : 0)
        )
      end

      def calculated_currency
        denominate_currency_code(code: currency_code)
      end
    end
  end
end
