module PaymentMethods
  class PaymentMethodsQuery < ::Base::Resolver
    description 'Get withdraw options'

    type !types[PaymentMethodType]

    def resolve(_obj, _args)
      PaymentMethodsResolver.call
    end
  end
end
