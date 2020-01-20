# frozen_string_literal: true

module Payments
  module Withdrawals
    class PaymentMethodEnum < Base::Enum
      graphql_name 'WithdrawalsPaymentMethodEnum'

      description 'Withdrawal payment methods'

      value ::Payments::Methods::CREDIT_CARD, 'MasterCard/Visa'
      value ::Payments::Methods::NETELLER, 'Neteller'
      value ::Payments::Methods::SKRILL, 'Skrill'
      value ::Payments::Methods::BITCOIN, 'Bitcoin'
      value ::Payments::Methods::ECO_PAYZ, 'ecoPayz'
      value ::Payments::Methods::IDEBIT, 'iDebit'
    end
  end
end
