# frozen_string_literal: true

module EveryMatrix
  class TablesOverviewQuery < ::Base::Resolver
    include DeviceChecker

    type types[EveryMatrix::OverviewType]

    description 'Casino Tables overview'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      EveryMatrix::Category
        .where(platform_type: platform_type(@request))
        .live_casino
    end
  end
end
