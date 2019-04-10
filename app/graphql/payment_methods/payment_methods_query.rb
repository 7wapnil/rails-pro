module PaymentMethods
  class PaymentMethodsQuery < ::Base::Resolver
    description 'Get withdraw options'

    type !types[PaymentMethodType]

    def resolve(_obj, _args)
      SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.values
                                                    .flatten
                                                    .compact
                                                    .uniq
    end
  end
end
