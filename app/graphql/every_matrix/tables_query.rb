# frozen_string_literal: true

module EveryMatrix
  class TablesQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType]

    description 'List of casino tables'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::PlayItemsResolver.call(
        model: EveryMatrix::Table,
        category_name: args['context'],
        device: platform_type(@request)
      )
    end
  end
end
