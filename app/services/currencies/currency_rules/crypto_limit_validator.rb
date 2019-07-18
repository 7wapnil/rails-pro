# frozen_string_literal: true

module Currencies
  module CurrencyRules
    class CryptoLimitValidator < ApplicationService
      M_BTC_MULTIPLIER = 1000
      CURRENCY_MAP = {
        'mBTC' => 'BTC',
        'mTBTC' => 'TBTC'
      }.freeze

      def initialize(currency:, params:)
        @currency = currency
        @params = params
      end

      def call
        check_limits!
      end

      private

      attr_reader :currency, :params

      def check_limits!
        return unless external_response.present?
        return if new_min_limit_valid?

        currency.errors.add(:base, :invalid)
        currency
          .entry_currency_rules
          .find(&:deposit?)
          .errors
          .add(:min_amount, limit_error)
      end

      def new_min_limit_valid?
        params['min_amount'].to_f > min_deposit_limit
      end

      def min_deposit_limit
        @min_deposit_limit ||=
          external_response.dig('minimum_amount').to_f * M_BTC_MULTIPLIER
      end

      def external_response
        @external_response ||= Payments::Crypto::CoinsPaid::Client
                               .new
                               .fetch_limits
                               .find(&method(:condition))
      end

      def limit_error
        I18n.t('errors.messages.crypto_deposit_limit', limit: min_deposit_limit)
      end

      def condition(object)
        object['currency'] == CURRENCY_MAP[currency.code]
      end
    end
  end
end
