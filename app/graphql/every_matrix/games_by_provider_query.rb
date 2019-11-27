# frozen_string_literal: true

module EveryMatrix
  class GamesByProviderQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType]

    description 'List of games by provider'

    argument :providerId, !types.ID

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::GamesByProviderResolver.call(
        provider_id: args['providerId'],
        device: platform_type(@request),
        country: @request.location.country_code.upcase
      )
    end
  end
end
