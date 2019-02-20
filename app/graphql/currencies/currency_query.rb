module Currencies
  class CurrencyQuery < ::Base::Resolver
    CACHE_KEY = 'cache/currencies'.freeze

    type !types[CurrencyType]

    description 'Get supported currencies'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      Rails.cache.fetch(CACHE_KEY, expires_in: 24.hours) do
        Currency.all
      end
    end
  end
end
