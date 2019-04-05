module Inputs
  class WithdrawInput < Base::InputObject
    description 'Input to create withdraw request'

    argument :password, String, required: true
    argument :amount, Float, required: true
    argument :wallet_id, ID, required: true
    argument :payment_method, String, required: true
    argument :payment_details, [Inputs::PaymentMethodDetail], required: true
  end
end
