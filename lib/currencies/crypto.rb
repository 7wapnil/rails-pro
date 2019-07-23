# frozen_string_literal: true

module Currencies
  module Crypto
    include Payments::Crypto::SuppliedCurrencies

    M_BTC_MULTIPLIER = 1000

    def multiply_amount(amount)
      amount * M_BTC_MULTIPLIER
    end

    def divide_amount(amount)
      amount / M_BTC_MULTIPLIER
    end
  end
end
