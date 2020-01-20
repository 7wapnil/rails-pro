# frozen_string_literal: true

module Payments
  module Methods
    CREDIT_CARD = 'credit_card'
    NETELLER = 'neteller'
    SKRILL = 'skrill'
    ECO_PAYZ = 'eco_payz'
    IDEBIT = 'idebit'
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
        name: ::Payments::Fiat::Wirecard::Methods::CREDIT_CARD,
        currency_kind: ::Currency::FIAT
      },
      NETELLER => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER,
        currency_kind: ::Currency::FIAT
      },
      SKRILL => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_MONEYBOOKERS,
        currency_kind: ::Currency::FIAT
      },
      ECO_PAYZ => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_ECO_PAYZ,
        currency_kind: ::Currency::FIAT
      },
      IDEBIT => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEBIT,
        currency_kind: ::Currency::FIAT
      },
      PAYSAFECARD => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_PAYSAFECARD,
        currency_kind: ::Currency::FIAT
      },
      SOFORT => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_SOFORT,
        currency_kind: ::Currency::FIAT
      },
      IDEAL => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEAL,
        currency_kind: ::Currency::FIAT
      },
      WEBMONEY => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_WEBMONEY,
        currency_kind: ::Currency::FIAT
      },
      YANDEX => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_YANDEXMONEY,
        currency_kind: ::Currency::FIAT
      },
      QIWI => {
        provider: ::Payments::Fiat::SafeCharge::Provider,
        name: ::Payments::Fiat::SafeCharge::Methods::APMGW_QIWI,
        currency_kind: ::Currency::FIAT
      },
      BITCOIN => {
        provider: ::Payments::Crypto::CoinsPaid::Provider,
        name: BITCOIN,
        currency_kind: ::Currency::CRYPTO,
        currency: ::Payments::Crypto::CoinsPaid::Currency::MBTC_CODE
      }
    }.freeze

    ALTERNATIVE_PAYMENT_METHODS = [
      SKRILL, NETELLER, ECO_PAYZ, IDEBIT, PAYSAFECARD,
      SOFORT, IDEAL, WEBMONEY, YANDEX, QIWI
    ].freeze

    CHOSEN_PAYMENT_METHODS = [
      CREDIT_CARD, SKRILL, NETELLER, ECO_PAYZ, IDEBIT
    ].freeze
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
