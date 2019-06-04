# frozen_string_literal: true

module Payments
  class DepositPaymentMethodEnum < Base::Enum
    description 'Deposit payment methods'

    value ::Payments::Methods::CREDIT_CARD, 'MasterCard/Visa'
    value ::Payments::Methods::NETELLER, 'Neteller'
    value ::Payments::Methods::SKRILL, 'Skrill'
    value ::Payments::Methods::PAYSAFECARD, 'Paysafecard'
    value ::Payments::Methods::BITCOIN, 'Bitcoin'
  end
end
