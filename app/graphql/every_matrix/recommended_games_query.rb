# frozen_string_literal: true

module EveryMatrix
  class RecommendedGamesQuery < ::Base::Resolver
    include DeviceChecker

    type !types[PlayItemType]

    description 'Get recommended games'

    argument :original_game_id, !types.Int

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      RecommendedGamesResolver.call(
        original_game_id: args.original_game_id,
        device: platform_type(@request),
        country: @request.location.country_code.upcase
      )
    end
  end
end
