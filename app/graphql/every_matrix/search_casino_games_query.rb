# frozen_string_literal: true

module EveryMatrix
  class SearchCasinoGamesQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType]

    description 'Search casino games'

    argument :query, !types.String
    argument :context, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::SearchPlayItemsResolver.call(
        query: args['query'],
        device: platform_type(@request),
        context: args['context']
      )
    end
  end
end
