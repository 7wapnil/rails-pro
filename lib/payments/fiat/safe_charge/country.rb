# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      # rubocop:disable Metrics/ModuleLength
      module Country
        AVAILABLE_COUNTRIES = {
          ::Payments::Fiat::SafeCharge::Methods::CC_CARD => %w[
            AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AX AZ
            BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ
            CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ
            DE DJ DK DM DO DZ
            EC EE EG EH ER ES ET
            FI FJ FK FM FO FR
            GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY
            HK HM HN HR HT HU
            ID IE IL IM IN IO IQ IR IS IT
            JE JM JO JP
            KE KG KH KI KM KN KP KR KS KW KY KZ
            LA LB LC LI LK LR LS LT LU LV LY
            MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ
            NA NC NE NF NG NI NL NO NP NR NU NZ
            OM
            PA PE PF PG PH PK PL PM PN PR PS PT PW PY
            QA
            RE RO RS RU RW
            SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ
            TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
            UA UG UM US UY UZ
            VA VC VE VG VI VN VU
            WS
            YE YT
            ZA ZM ZW
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_MONEYBOOKERS => %w[
            AD AE AF AG AI AL AM AN AO AQ AR AT AU AW AX AZ
            BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BV BW BY BZ
            CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CX CY CZ
            DE DJ DK DM DO DZ
            EC EE EG EH ER ES ET
            FI FJ FK FM FO FR
            GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY
            HK HM HN HR HT HU
            ID IE IL IM IN IO IQ IR IS IT
            JE JM JO JP
            KE KG KH KI KM KN KR KW KY KZ
            LA LB LC LI LK LR LS LT LU LV LY
            MA MC MD ME MG MH MK ML MM MN MO MQ MR MS MT MU MV MW MX MY MZ
            NA NC NE NF NG NI NL NO NP NR NU NZ
            OM
            PA PE PF PG PH PK PL PM PN PR PS PT PW PY
            QA
            RE RO RS RU RW
            SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ
            TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
            UA UG UY UZ
            VA VC VE VG VI VN VU
            WF WS
            YE YT
            ZA ZM ZW
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER => %w[
            AD AE AF AG AI AL AM AN AO AQ AR AT AU AW AZ
            BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BV BW BY BZ
            CA CC CF CG CH CI CK CL CM CO CR CU CV CX CY CZ
            DE DJ DK DM DO DZ
            EC EE EG EH ER ES ET
            FI FJ FK FM FO FR
            GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GT GU GW GY
            HK HM HN HR HT HU
            ID IE IL IM IN IO IQ IR IS IT
            JE JM JO JP
            KE KG KH KI KM KN KR KW KY KZ
            LA LB LC LI LK LR LS LT LU LV LY
            MA MC MD ME MG MH MK ML MM MN MO MQ MR MS MT MU MV MW MX MY MZ
            NA NC NE NF NG NI NL NO NP NR NU NZ
            OM
            PA PE PF PG PH PK PL PM PN PS PT PW PY
            QA
            RE RO RS RU RW
            SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ
            TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
            UA UG US UY UZ
            VA VC VE VG VN VU
            WF WS
            YE YT
            ZA ZM ZW
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_ECO_PAYZ => %w[
            AD AE AG AI AN AQ AR AT AU AW AX
            BA BB BD BE BG BH BM BO BR BS BV BZ
            CA CC CG CH CK CL CN CO CR CV CX CY CZ
            DE DK DM DO
            EC EE EG ES
            FI FJ FK FO FR
            GB GD GE GF GG GI GL GP GR GS GU GY
            HK HM HN HR HU
            IE IL IM IN IO IS IT
            JE JM JO JP
            KM KN KR KW KY
            LC LI LK LT LU LV
            MC MD ME MH MK MN MO MP MQ MR MS MT MU MV MX MY
            NA NC NF NI NL NO NP NZ
            OM
            PA PE PF PG PK PL PM PN PR PT PW PY
            QA
            RE RO RU
            SA SB SC SE SG SH SI SJ SK SM SR ST SV
            TC TF TH TL TM TO TR TT TV TW
            UA UM US UY UZ
            VA VC VE VG VI
            WF WS
            YT
            ZA
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEBIT => %w[CA].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_PAYSAFECARD => %w[
            AD AE AR AT AU
            BE BG
            CA CH CY CZ
            DE DK
            ES
            FI FR
            GB GE GI
            HR HU
            IE IT
            KW
            LI LT LU LV
            MT MX
            NL NO NZ
            PE PL PT
            RO
            SA SE SI SK
            UY
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_SOFORT => %w[
            AT BE CH DE ES FR GB IT NL PL SK
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_IDEAL => %w[NL].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_WEBMONEY => %w[
            AM AZ
            BY
            GE
            KG KZ
            LT LV
            MD
            RU
            TJ TM
            UZ
            VN
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_YANDEXMONEY => %w[
            AM AZ
            BY
            GE
            KG KZ
            MD
            RU
            TJ TM
            UA UZ
          ].freeze,
          ::Payments::Fiat::SafeCharge::Methods::APMGW_QIWI => %w[
            AM AZ
            BY
            EE
            GB GE
            IL IN
            JP
            KG KR KZ
            LT LV
            MD
            PA
            RU
            TH TJ TR
            UA US UZ
            VN
          ].freeze
        }.freeze
      end
      # rubocop:enable Metrics/ModuleLength
    end
  end
end
