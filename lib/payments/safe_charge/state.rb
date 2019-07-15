# frozen_string_literal: true

module Payments
  module SafeCharge
    module State
      AVAILABLE_USA_STATES = %w[
        AK AL AR AS AZ
        CA CO CT
        DC DE
        FL FM
        GA GU
        HI
        IA ID IL IN
        KS KY
        LA
        MA MD ME MH MI MN MO MP MS MT
        NC ND NE NH NJ NM NV NY
        OH OK OR
        PA PR PW
        RI
        SC SD
        TN TX
        UT
        VA VI VT
        WA WI WV WY
      ].freeze

      AVAILABLE_CANADIAN_STATES = %w[
        AB
        BC
        MB
        NB NF NS NT NU
        ON
        PE
        QC
        SK
        YT
      ].freeze

      AVAILABLE_INDIAN_STATES = %w[
        AN AP AR AS
        BR
        CG CH
        DD DL DN
        GA GJ
        HP HR
        JH JK
        KA KL
        LD
        MH ML MN MP MZ
        NL
        OR
        PB PY
        RJ
        SK
        TN TR
        UA UP
        WB
      ].freeze

      AVAILABLE_STATES = {
        'US' => AVAILABLE_USA_STATES,
        'CA' => AVAILABLE_CANADIAN_STATES,
        'IN' => AVAILABLE_INDIAN_STATES
      }.freeze
    end
  end
end
