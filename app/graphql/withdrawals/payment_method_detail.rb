# frozen_string_literal: true

module Withdrawals
  class PaymentMethodDetail < Base::InputObject
    description 'Payment detail in format key -> value'

    argument :code, String, required: true
    argument :value, String, required: true
  end
end
