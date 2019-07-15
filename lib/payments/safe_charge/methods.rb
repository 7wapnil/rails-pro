# frozen_string_literal: true

module Payments
  module SafeCharge
    module Methods
      CC_CARD = 'cc_card'
      APMGW_MONEYBOOKERS = 'apmgw_MoneyBookers'
      APMGW_NETELLER = 'apmgw_Neteller'
      APMGW_PAYSAFECARD = 'apmgw_PaySafeCard'
      APMGW_SOFORT = 'apmgw_Sofort'
      APMGW_IDEAL = 'apmgw_iDeal'
      APMGW_WEBMONEY = 'apmgw_WebMoney'
      APMGW_YANDEXMONEY = 'apmgw_YANDEXMONEY'
      APMGW_QIWI = 'apmgw_QIWI'

      PAYMENT_METHOD_MAP = {
        CC_CARD => ::Payments::Methods::CREDIT_CARD,
        APMGW_MONEYBOOKERS => ::Payments::Methods::SKRILL,
        APMGW_NETELLER => ::Payments::Methods::NETELLER,
        APMGW_PAYSAFECARD => ::Payments::Methods::PAYSAFECARD,
        APMGW_SOFORT => ::Payments::Methods::SOFORT,
        APMGW_IDEAL => ::Payments::Methods::IDEAL,
        APMGW_WEBMONEY => ::Payments::Methods::WEBMONEY,
        APMGW_YANDEXMONEY => ::Payments::Methods::YANDEX,
        APMGW_QIWI => ::Payments::Methods::QIWI
      }.freeze

      IDENTIFIERS_MAP = {
        ::Payments::Methods::CREDIT_CARD => :last_four_digits,
        ::Payments::Methods::SKRILL => :email,
        ::Payments::Methods::NETELLER => :account_id
      }.freeze
    end
  end
end
