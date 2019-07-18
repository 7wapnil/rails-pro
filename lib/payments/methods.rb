# frozen_string_literal: true

module Payments
  module Methods
    CREDIT_CARD = 'credit_card'
    NETELLER = 'neteller'
    SKRILL = 'skrill'
    PAYSAFECARD = 'paysafecard'
    SOFORT = 'sofort'
    IDEAL = 'ideal'
    WEBMONEY = 'webmoney'
    YANDEX = 'yandex'
    QIWI = 'qiwi'
    BITCOIN = 'bitcoin'

    METHOD_PROVIDERS = {
      CREDIT_CARD => {
        provider: ::Payments::Fiat::Wirecard::Provider,
        name: ::Payments::Fiat::Wirecard::Methods::CREDIT_CARD
      },
      NETELLER => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER
      },
      SKRILL => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_MONEYBOOKERS
      },
      PAYSAFECARD => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_PAYSAFECARD
      },
      SOFORT => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_SOFORT
      },
      IDEAL => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEAL
      },
      WEBMONEY => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_WEBMONEY
      },
      YANDEX => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_YANDEXMONEY
      },
      QIWI => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_QIWI
      },
      BITCOIN => {
        provider: ::Payments::Crypto::CoinsPaid::Provider,
        name: BITCOIN,
        currency: ::Payments::Crypto::CoinsPaid::Currency::MBTC_CODE
      }
    }.freeze

    ALTERNATIVE_PAYMENT_METHODS = [
      SKRILL, NETELLER, PAYSAFECARD, SOFORT, IDEAL, WEBMONEY, YANDEX, QIWI
    ].freeze

    CHOSEN_PAYMENT_METHODS = [CREDIT_CARD, SKRILL, NETELLER].freeze
    ENTERED_PAYMENT_METHODS = [BITCOIN].freeze

    def find_method_provider(method)
      find_provider_config(method)[:provider]
    end

    def provider_method_name(method)
      find_provider_config(method)[:name]
    end

    def find_provider_config(method)
      config = METHOD_PROVIDERS[method]
      return config if config.present?

      err_msg = "No provider found for method #{method}"
      raise Payments::NotSupportedError, err_msg
    end
  end
end
