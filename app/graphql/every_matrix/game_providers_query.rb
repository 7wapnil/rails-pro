# frozen_string_literal: true

module EveryMatrix
  class GameProvidersQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[ProviderType]

    description 'List of providers'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      EveryMatrix::ContentProvider.distinct
    end
  end
end
