# frozen_string_literal: true

module Inputs
  class WithdrawInput < Base::InputObject
    description 'Input to create withdraw request'

    argument :password, String, required: true
    argument :amount, Float, required: true
    argument :walletId, ID, required: true
    argument :paymentMethod, ::Payments::WithdrawalPaymentMethodEnum,
             required: true
    argument :paymentDetails, [Inputs::PaymentMethodDetail], required: true
  end
end
