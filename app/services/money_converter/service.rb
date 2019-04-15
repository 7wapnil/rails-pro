# frozen_string_literal: true

module MoneyConverter
  class Service < ApplicationService
    def convert(value, from_currency_code, to_currency_code = 'EUR')
      from_currency_code.upcase
      to_currency_code.upcase
      return value if from_currency_code == to_currency_code

      exchange_rate = Cryptocompare::Price
                      .find(from_currency_code, to_currency_code)
                      &.dig(from_currency_code, to_currency_code)
      return value unless exchange_rate

      value * exchange_rate
    end
  end
end
