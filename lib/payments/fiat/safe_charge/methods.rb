# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Methods
        CC_CARD = 'cc_card'
        APMGW_MONEYBOOKERS = 'apmgw_MoneyBookers'
        APMGW_NETELLER = 'apmgw_Neteller'
        APMGW_PAYSAFECARD = 'apmgw_PaySafeCard'
        APMGW_SOFORT = 'apmgw_Sofort'
        APMGW_IDEAL = 'apmgw_iDeal'
        APMGW_IDEBIT = 'apmgw_iDebit'
        APMGW_WEBMONEY = 'apmgw_WebMoney'
        APMGW_YANDEXMONEY = 'apmgw_YANDEXMONEY'
        APMGW_QIWI = 'apmgw_QIWI'

        PAYMENT_METHOD_MAP = {
          CC_CARD => ::Payments::Methods::CREDIT_CARD,
          APMGW_MONEYBOOKERS => ::Payments::Methods::SKRILL,
          APMGW_NETELLER => ::Payments::Methods::NETELLER,
          APMGW_PAYSAFECARD => ::Payments::Methods::PAYSAFECARD,
          APMGW_IDEBIT => ::Payments::Methods::IDEBIT,
          APMGW_SOFORT => ::Payments::Methods::SOFORT,
          APMGW_IDEAL => ::Payments::Methods::IDEAL,
          APMGW_WEBMONEY => ::Payments::Methods::WEBMONEY,
          APMGW_YANDEXMONEY => ::Payments::Methods::YANDEX,
          APMGW_QIWI => ::Payments::Methods::QIWI
        }.freeze

        NAME_IDENTIFIERS_MAP = {
          ::Payments::Methods::CREDIT_CARD => 'ccCardNumber',
          ::Payments::Methods::SKRILL => 'account_id',
          ::Payments::Methods::NETELLER => 'nettelerAccount',
          ::Payments::Methods::IDEBIT => 'iDebit_account_id'
        }.freeze
      end
    end
  end
end
