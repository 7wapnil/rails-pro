# frozen_string_literal: true

module EveryMatrix
  class GamesQuery < ::Base::Resolver
    ITEMS_LIMIT = 35

    type !types[PlayItemType]

    description 'List of casino games'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::Game.items_per_category(args['context']).limit(ITEMS_LIMIT)
    end
  end
end
