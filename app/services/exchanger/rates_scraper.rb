module Exchanger
  class RatesScraper < ApplicationService
    def call
      update_fiat_rates
      update_crypto_rates
    end

    private

    def update_fiat_rates
      return unless fiat_currencies

      Exchanger::Apis::ExchangeRatesApiIo
        .call(::Currency::PRIMARY_CODE, fiat_currencies)
        .each(&method(:update_rate))
    end

    def update_crypto_rates
      return unless crypto_currencies

      Exchanger::Apis::CoinApi
        .call(::Currency::PRIMARY_CODE, crypto_currencies)
        .each(&method(:update_rate))
    end

    def update_rate(rate)
      currency = ::Currency.find_by!(code: rate.code)
      currency.update_attributes(exchange_rate: rate.value)

      Rails.logger.info "Rate for '#{rate.code}' updated to #{rate.value}"
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Currency '#{rate.code}' not found"
    rescue StandardError => e
      Rails.logger.error e.message
    end

    def fiat_currencies
      @fiat_currencies ||= ::Currency.fiat.pluck(:code)
    end

    def crypto_currencies
      @crypto_currencies ||= ::Currency.crypto.pluck(:code)
    end
  end
end