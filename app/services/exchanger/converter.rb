module Exchanger
  class Converter < ApplicationService
    PRECISION = 2

    def initialize(value, origin_currency, target_currency = nil)
      @value = value
      @origin_code = origin_currency # origin_currency
      @target_code = target_currency || ::Currency::PRIMARY_CODE

      @origin_currency = origin_currency if origin_currency.is_a? Currency
      @target_currency = target_currency if target_currency.is_a? Currency
    end

    def call
      return @value.truncate(PRECISION) if @origin_code == @target_code

      convert
    end

    private

    def convert
      converted_value.truncate(PRECISION)
    end

    def converted_value
      converted = @value / currency_rate(origin_currency)
      return converted if target_currency.primary?

      converted * currency_rate(target_currency)
    end

    def origin_currency
      @origin_currency ||= ::Currency.find_by!(code: @origin_code)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Currency #{@origin_code} not found"
    end

    def target_currency
      @target_currency ||= ::Currency.find_by!(code: @target_code)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Currency #{@target_code} not found"
    end

    def currency_rate(currency)
      return ::Currency::PRIMARY_RATE if currency.primary?

      rate = currency.exchange_rate
      return rate.to_f if rate

      raise StandardError, "Currency '#{currency.code}' has no updated rate"
    end

    def validate_rate!(currency)
      return if currency.code == ::Currency::PRIMARY_CODE
      return if currency.exchange_rate

      err_msg = "Currency '#{currency.code}' has no updated exchange rate"
      raise StandardError, err_msg
    end
  end
end
