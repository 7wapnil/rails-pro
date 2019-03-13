module PaymentMethods
  class PaymentMethodsQuery < ::Base::Resolver
    description 'Get withdraw options'

    type types[PaymentMethodType]

    def resolve(_obj, _args)
      PaymentMethodsResolver.call(current_customer: @current_customer)
    end
  end
end
