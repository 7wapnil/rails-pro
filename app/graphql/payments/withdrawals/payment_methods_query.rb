# frozen_string_literal: true

module Payments
  module Withdrawals
    class PaymentMethodsQuery < ::Base::Resolver
      description 'Get withdrawal options'

      type !types[PaymentMethodType]

      def resolve(_obj, _args)
        ::Payments::Withdraw::PAYMENT_METHODS
      end
    end
  end
end
