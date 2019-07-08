# frozen_string_literal: true

module Payments
  module CoinsPaid
    module Currency
      BTC_CODE = ENV.fetch('COINSPAID_MODE', 'test') == 'test' ? 'TBTC' : 'BTC'
      MBTC_CODE = "m#{BTC_CODE}"
    end
  end
end
