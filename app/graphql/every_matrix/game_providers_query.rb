# frozen_string_literal: true

module EveryMatrix
  class GameProvidersQuery < ::Base::Resolver
    type !types[ProviderType]

    description 'List of providers'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      GamesProviderResolver.call
    end
  end
end
