# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      # rubocop:disable Metrics/ModuleLength
      module Currency
        AVAILABLE_CURRENCY_LIST = {
          ::Payments::Fiat::SafeCharge::Methods::CC_CARD => %w[
            AED ARS AUD AZN
            BGN BHD BND BRL BYN BYR
            CAD CHF CLP CNH CNY COP CRC CZK
            DKK DZD
            EEK EGP EUR
            GBP GEL
            HKD HRK HUF
            IDR INR IQD ISK
            JOD
            KGS KRW KWD KZT
            LBP LTL LVL
            MAD MDL MXN MYR
            NIS NOK NZD
            OMR
            PEN PHP PKR PLN
            QAR
            RON RSD RUB
            SAR SEK SGD SKK
            THB TND TRY TWD
            UAH USD UYU
            VEF VND
            YEN YER
            ZAR
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_MONEYBOOKERS => %w[
            AED AUD
            BGN
            CAD CHF CZK
            DKK
            EEK EUR
            GBP
            HKD HRK HUF
            INR ISK
            JPY
            KRW
            MYR
            NIS NOK NZD
            PLN
            RON
            SEK SGD
            THB TRY TWD
            USD
            ZAR
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER => %w[
            AUD
            BGN BRL
            CAD
            DKK
            EUR
            GBP
            HUF
            INR
            JPY
            LTL LVL
            MXN
            NOK
            PLN
            RON RUB
            SEK
            USD
            ZAR
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_ECO_PAYZ => %w[
            AED ARS AUD
            BGN BRL
            CAD CHF CLP CNY COP CZK
            DKK
            EUR
            GBP
            HKD HUF
            INR ISK
            JPY
            LTL LVL
            MDL MXN MYR
            NIS NOK NZD
            PEN PLN
            RON RSD RUB
            SEK SGD
            THB TRY
            UAH USD UYU
            VEF
            ZAR
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEBIT => %w[
            CAD USD
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_PAYSAFECARD => %w[
            AUD
            BGN
            CAD CHF
            DKK
            EUR
            GBP
            HRK HUF
            MXN
            NOK NZD
            RON
            SEK
            USD
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_SOFORT => %w[
            EUR GBP
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEAL => %w[
            AUD CAD DKK EUR GBP HKD NOK SEK USD
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_WEBMONEY => %w[
            EUR RUB USD
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_YANDEXMONEY => %w[
            RUB USD
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_QIWI => %w[
            EUR RUB USD
          ].freeze
        }.freeze
      end
      # rubocop:enable Metrics/ModuleLength
    end
  end
end
