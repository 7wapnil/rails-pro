# frozen_string_literal: true

module Exchanger
  module Apis
    class CryptoRatesApi < ApplicationService
      include ::Currencies::Crypto
      include HTTParty

      raise_on [400, 401, 403, 429, 500, 550]
      base_uri 'https://api.cryptonator.com/api/ticker'

      def initialize(base_currency_code, currency_codes)
        @base_currency_code = base_currency_code
        @currency_codes = currency_codes
      end

      def call
        Rails.logger.info(log_params('Requesting new currencies rates'))

        collect_rates!
      rescue HTTParty::ResponseError, HTTParty::CryptoRatesResponseError => e
        Rails.logger.error(log_params(e.message).merge(error_object: e))

        []
      end

      private

      attr_reader :base_currency_code, :currency_codes

      def collect_rates!
        currency_codes
          .reject { |code| [M_TBTC, BTC, TBTC].include?(code) }
          .map { |code| parse(request(code)) }
          .tap { |rates| replace_btc_with_m_btc(rates) }
      end

      def request(code)
        self.class.get("/#{base_currency_code}-#{external_code(code)}")
      end

      def external_code(code)
        return code if CURRENCY_CONVERTING_MAP.exclude?(code)

        CURRENCY_CONVERTING_MAP[code]
      end

      def parse(response)
        response_error(response) unless response['success']

        Rate.new(
          response['ticker']['target'],
          response['ticker']['price'].to_f
        )
      end

      def response_error(response)
        raise HTTParty::CryptoRatesResponseError, response['error']
      end

      def replace_btc_with_m_btc(rates)
        btc_rate = rates.find { |rate| rate.code == BTC }

        return unless btc_rate

        m_btc_rate = Rate.new(m_btc_code, multiply_amount(btc_rate.value))

        rates[rates.index(btc_rate)] = m_btc_rate
      end

      def m_btc_code
        Rails.env.production? ? M_BTC : M_TBTC
      end

      def log_params(message)
        {
          message:              message,
          api:                  self.class.name,
          base_currency:        base_currency_code,
          currencies_to_update: currency_codes
        }
      end
    end
  end
end
