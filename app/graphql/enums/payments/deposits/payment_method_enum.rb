# frozen_string_literal: true

module Payments
  module Deposits
    class PaymentMethodEnum < Base::Enum
      graphql_name 'DepositsPaymentMethodEnum'

      description 'Deposit payment methods'

      value ::Payments::Methods::CREDIT_CARD, 'MasterCard/Visa'
      value ::Payments::Methods::NETELLER, 'Neteller'
      value ::Payments::Methods::SKRILL, 'Skrill'
      value ::Payments::Methods::PAYSAFECARD, 'Paysafecard'
      value ::Payments::Methods::BITCOIN, 'Bitcoin'
    end
  end
end
