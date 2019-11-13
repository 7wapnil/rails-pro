# frozen_string_literal: true

module EveryMatrix
  class TablesQuery < ::Base::Resolver
    include DeviceChecker

    type !types[PlayItemType]

    description 'List of casino games'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::PlayItemsResolver.call(
        model: EveryMatrix::Table,
        category_name: args['context'],
        device: platform_type(@request),
        country: @request.location.country_code.upcase
      )
    end
  end
end
