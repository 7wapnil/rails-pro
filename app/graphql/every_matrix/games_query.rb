# frozen_string_literal: true

module EveryMatrix
  class GamesQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[GameType]

    description 'List of casino games'

    def auth_protected?
      false
    end

    def resolve(*)
      Game.order(max_hit_frequency: :desc)
    end
  end
end
