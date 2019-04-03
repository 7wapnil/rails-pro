# frozen_string_literal: true

module Inputs
  class PaymentMethodDetail < Base::InputObject
    description 'Payment detail in format name -> value'

    argument :code, String, required: true
    argument :value, String, required: true
  end
end
