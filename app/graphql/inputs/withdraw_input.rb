# frozen_string_literal: true

module Inputs
  class WithdrawInput < Base::InputObject
    description 'Input to create withdraw request'

    argument :password, String, required: true
    argument :amount, Float, required: true
    argument :currencyCode, String, required: true
    argument :paymentMethod, ::Payments::Withdrawals::PaymentMethodEnum,
             required: true
    argument :paymentDetails, [Inputs::PaymentMethodDetail], required: true
  end
end
