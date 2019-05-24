module Payments
  module Methods
    CREDIT_CARD = :credit_card
    NETELLER = :neteller
    SKRILL = :skrill
    PAYSAFECARD = :paysafecard
    SOFORT = :sofort
    IDEAL = :ideal
    WEBMONEY = :webmoney
    YANDEX = :yandex
    QIWI = :qiwi

    METHOD_PROVIDERS = {
      CREDIT_CARD => {
        provider: Wirecard::Provider,
        name: 'creditcard'
      },
      NETELLER => {
        provider: SafeCharge::Provider,
        name: 'apmgw_Neteller'
      },
      SKRILL => {
        provider: SafeCharge::Provider,
        name: 'apmgw_MoneyBookers'
      },
      PAYSAFECARD => {
        provider: SafeCharge::Provider,
        name: 'apmgw_PaySafeCard'
      },
      SOFORT => {
        provider: SafeCharge::Provider,
        name: 'apmgw_Sofort'
      },
      IDEAL => {
        provider: SafeCharge::Provider,
        name: 'apmgw_iDeal'
      },
      WEBMONEY => {
        provider: SafeCharge::Provider,
        name: 'apmgw_WebMoney'
      },
      YANDEX => {
        provider: SafeCharge::Provider,
        name: 'apmgw_YANDEXMONEY'
      },
      QIWI => {
        provider: SafeCharge::Provider,
        name: 'apmgw_QIWI'
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
