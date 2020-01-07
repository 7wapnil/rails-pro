# frozen_string_literal: true

module EveryMatrix
  class RecommendedGamesQuery < ::Base::Resolver
    include DeviceChecker

    type !types[PlayItemType]

    description 'Get recommended games'

    argument :originalGameId, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      RecommendedGamesResolver.call(
        original_game_id: args[:originalGameId],
        device: platform_type(@request)
      )
    end
  end
end
