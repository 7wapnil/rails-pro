# frozen_string_literal: true

module Payments
  module ExternalProviders
    SAFE_CHARGE = 'safe_charge'
    WIRECARD = 'wirecard'
    COINS_PAID = 'coins_paid'

    MAP = {
      SAFE_CHARGE => ::Payments::SafeCharge::Provider,
      WIRECARD => ::Payments::Wirecard::Provider,
      COINS_PAID => ::Payments::CoinsPaid::Provider
    }.freeze
  end
end
