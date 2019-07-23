# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Currency
        include SuppliedCurrencies

        COINSPAID_MODE = ENV.fetch('COINSPAID_MODE', 'test')
        BTC_CODE = COINSPAID_MODE == 'test' ? TBTC : BTC
        MBTC_CODE = "m#{BTC_CODE}"
      end
    end
  end
end
