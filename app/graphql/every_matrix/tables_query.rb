# frozen_string_literal: true

module EveryMatrix
  class TablesQuery < ::Base::Resolver
    ITEMS_LIMIT = 35

    type !types[PlayItemType]

    description 'List of casino games'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::Table.items_per_category(args['context']).limit(ITEMS_LIMIT)
    end
  end
end
