# frozen_string_literal: true

module Exchanger
  class RatesScraper < ApplicationService
    include ::Payments::Crypto::SuppliedCurrencies

    def call
      update_fiat_rates
      update_crypto_rates
    end

    private

    def update_fiat_rates
      return unless fiat_currencies

      Exchanger::Apis::ExchangeRatesApi
        .call(::Currency::PRIMARY_CODE, fiat_currencies)
        .each(&method(:update_rate))
    end

    def update_crypto_rates
      return unless crypto_currencies

      Exchanger::Apis::CryptoRatesApi
        .call(::Currency::PRIMARY_CODE, crypto_currencies)
        .each(&method(:update_rate))
    end

    def update_rate(rate)
      currency = ::Currency.find_by!(code: rate.code)
      currency.update_attributes(exchange_rate: rate.value)

      Rails.logger.info(
        message: 'Exchange rate updated',
        code: rate.code,
        value: rate.value
      )
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error(
        message: 'Currency not found', code: rate.code, error_object: e
      )
    rescue StandardError => e
      Rails.logger.error(error_object: e, message: e.message)
    end

    def fiat_currencies
      @fiat_currencies ||= ::Currency.fiat.pluck(:code)
    end

    def crypto_currencies
      @crypto_currencies ||= ::Currency.crypto.pluck(:code) | [BTC]
    end
  end
end
