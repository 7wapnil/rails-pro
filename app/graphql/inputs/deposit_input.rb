# frozen_string_literal: true

module Inputs
  class DepositInput < Base::InputObject
    description 'Input to create deposit request'

    argument :paymentMethod, ::Payments::Deposits::PaymentMethodEnum,
             required: true
    argument :currencyCode, String, required: true
    argument :amount, Float, required: true
    argument :bonusCode, String, required: false
  end
end
