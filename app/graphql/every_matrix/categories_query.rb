# frozen_string_literal: true

module EveryMatrix
  class CategoriesQuery < ::Base::Resolver
    include DeviceChecker

    type !types[CategoryType]

    description 'List of casino games'

    argument :kind, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::Category.where(
        kind: args['kind'],
        platform_type: platform_type(@request)
      )
    end
  end
end
