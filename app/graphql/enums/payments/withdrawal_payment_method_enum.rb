# frozen_string_literal: true

module Payments
  class WithdrawalPaymentMethodEnum < Base::Enum
    description 'Withdrawal payment methods'

    value ::Payments::Methods::CREDIT_CARD, 'MasterCard/Visa'
    value ::Payments::Methods::NETELLER, 'Neteller'
    value ::Payments::Methods::SKRILL, 'Skrill'
    value ::Payments::Methods::BITCOIN, 'Bitcoin'
  end
end
