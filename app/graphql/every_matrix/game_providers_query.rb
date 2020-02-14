# frozen_string_literal: true

module EveryMatrix
  class GameProvidersQuery < ::Base::Resolver
    type !types[EveryMatrix::ProviderType]

    description 'List of providers'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      [
        *EveryMatrix::ContentProvider.visible.as_vendor.distinct,
        *EveryMatrix::Vendor.visible.distinct
      ].sort_by(&method(:sort_algorithm))
    end

    private

    def sort_algorithm(provider)
      provider.position.presence || Float::INFINITY
    end
  end
end
