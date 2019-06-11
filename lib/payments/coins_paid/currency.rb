# frozen_string_literal: true

module Payments
  module CoinsPaid
    module Currencies
      BTC_CODE = ENV.fetch('COINSPAID_MODE', 'test') == 'test' ? 'TBTC' : 'BTC'
    end
  end
end
