# frozen_string_literal: true

module Payments
  module Crypto
    module SuppliedCurrencies
      BTC = 'BTC'
      TBTC = 'TBTC'
      M_BTC = 'mBTC'
      M_TBTC = 'mTBTC'

      CURRENCY_CONVERTING_MAP = {
        BTC => M_BTC,
        TBTC => M_TBTC,
        M_BTC => BTC,
        M_TBTC => TBTC
      }.freeze
    end
  end
end
