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
        provider: ::Payments::Wirecard::Provider,
        name: Wirecard::Methods::CREDIT_CARD
      },
      NETELLER => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_NETELLER
      },
      SKRILL => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_MONEYBOOKERS
      },
      PAYSAFECARD => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_PAYSAFECARD
      },
      SOFORT => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_SOFORT
      },
      IDEAL => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_IDEAL
      },
      WEBMONEY => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_WEBMONEY
      },
      YANDEX => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_YANDEXMONEY
      },
      QIWI => {
        provider: ::Payments::SafeCharge::Provider,
        name: SafeCharge::Methods::APMGW_QIWI
      },
      BITCOIN => {
        provider: ::Payments::CoinsPaid::Provider,
        name: 'bitcoin'
      }
    }.freeze

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
