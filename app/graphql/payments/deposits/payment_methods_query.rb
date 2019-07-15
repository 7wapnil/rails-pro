# frozen_string_literal: true

module Payments
  module Deposits
    class PaymentMethodsQuery < ::Base::Resolver
      description 'Get deposit options'

      type !types[PaymentMethodType]

      def resolve(_obj, _args)
        ::Payments::Deposit::PAYMENT_METHODS
      end
    end
  end
end