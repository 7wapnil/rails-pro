# frozen_string_literal: true

module EveryMatrix
  class GamesOverviewQuery < ::Base::Resolver
    include DeviceChecker

    type types[EveryMatrix::OverviewType]

    description 'Casino Games overview'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      EveryMatrix::Category
        .where(platform_type: platform_type(@request))
        .casino
    end
  end
end
