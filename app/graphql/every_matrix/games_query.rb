# frozen_string_literal: true

module EveryMatrix
  class GamesQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType]

    description 'List of casino games'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::PlayItemsResolver.call(
        model: EveryMatrix::Game,
        category_name: args['context'],
        device: platform_type(@request),
        country: @request.location.country_code.upcase
      )
    end
  end
end
