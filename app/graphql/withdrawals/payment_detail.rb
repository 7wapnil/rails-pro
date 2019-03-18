# frozen_string_literal: true

module Withdrawals
  class PaymentDetail < Base::InputObject
    description 'Payment detail in format key -> value'

    argument :key, String, required: true
    argument :value, String, required: true
  end
end
