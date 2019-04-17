module Exchanger
  class Converter < ApplicationService
    def initialize(value, origin_currency, target_currency = nil)
      @value = value
      @origin_currency = origin_currency
      @target_currency = target_currency || Currency::PRIMARY_CODE
    end

    def call
    end
  end
end
