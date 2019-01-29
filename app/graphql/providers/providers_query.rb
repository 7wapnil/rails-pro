module Providers
  class ProvidersQuery < ::Base::Resolver
    type !types[ProviderType]

    description 'Get all Radar providers'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      Radar::Producer.all
    end
  end
end
