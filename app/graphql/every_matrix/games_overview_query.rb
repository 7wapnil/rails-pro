# frozen_string_literal: true

module EveryMatrix
  class GamesOverviewQuery < ::Base::Resolver
    type types[EveryMatrix::OverviewType]

    description 'Casino Games overview'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      EveryMatrix::Category.casino
    end
  end
end
