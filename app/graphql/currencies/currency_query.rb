module Currencies
  class CurrencyQuery < ::Base::Resolver
    type !types[CurrencyType]

    description 'Get supported currencies'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      Currency.cached_all
    end
  end
end
