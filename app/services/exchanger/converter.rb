# frozen_string_literal: true

module Exchanger
  class Converter < ApplicationService
    PRECISION = 2

    def initialize(value, origin_currency, target_currency = nil)
      @value = value
      @origin = origin_currency
      @target = target_currency || ::Currency::PRIMARY_CODE
    end

    def call
      return value.truncate(PRECISION) if origin_currency == target_currency

      converted_value.truncate(PRECISION)
    end

    private

    attr_reader :value, :origin, :target

    def converted_value
      value / currency_rate(origin_currency) * currency_rate(target_currency)
    end

    def origin_currency
      @origin_currency ||=
        origin.is_a?(Currency) ? origin : ::Currency.find_by!(code: origin)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Currency #{origin} not found"
    end

    def target_currency
      @target_currency ||=
        target.is_a?(Currency) ? target : ::Currency.find_by!(code: target)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Currency #{target} not found"
    end

    def currency_rate(currency)
      rate = currency.exchange_rate

      return rate.to_f if rate

      raise StandardError, "Currency '#{currency}' has no updated rate"
    end
  end
end
