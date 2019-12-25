# frozen_string_literal: true

module EveryMatrix
  class TablesOverviewQuery < ::Base::Resolver
    type types[EveryMatrix::OverviewType]

    description 'Casino Tables overview'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      EveryMatrix::Category.live_casino
    end
  end
end
