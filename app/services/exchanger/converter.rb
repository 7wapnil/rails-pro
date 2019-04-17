module Exchanger
  class Converter < ApplicationService
    def initialize(value, origin_code, target_code = nil)
      @value = value
      @origin_code = origin_code
      @target_code = target_code || ::Currency::PRIMARY_CODE
    end

    def call
      return @value if @origin_code == @target_code

      convert
    end

    private

    def convert
      converted_value.truncate(4)
    end

    def converted_value
      converted = @value / currency_rate(origin_currency)
      return converted if target_currency.primary?

      converted * currency_rate(target_currency)
    end

    def origin_currency
      @origin_currency ||= ::Currency.find_by!(code: @origin_code)
    end

    def target_currency
      @target_currency ||= ::Currency.find_by!(code: @target_code)
    end

    def currency_rate(currency)
      return ::Currency::PRIMARY_RATE if currency.primary?

      rate = currency.exchange_rate
      return rate.to_f unless rate.nil?

      raise StandardError, "Currency '#{currency.code}' has no updated rate"
    end

    def validate_rate!(currency)
      return if currency.code == ::Currency::PRIMARY_CODE
      return unless currency.exchange_rate.nil?

      err_msg = "Currency '#{currency.code}' has no updated exchange rate"
      raise StandardError, err_msg
    end
  end
end
