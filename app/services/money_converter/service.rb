module MoneyConverter
  class Service < ApplicationService
    def convert(value, from_currency_code, to_currency_code = 'EUR')
      return value if from_currency_code == to_currency_code

      exchange_rate = Cryptocompare::Price
                      .find(from_currency_code, to_currency_code)
                      &.dig(from_currency_code, to_currency_code)

      raise 'Currency exchange rate not available' unless exchange_rate

      value * exchange_rate
    end
  end
end
