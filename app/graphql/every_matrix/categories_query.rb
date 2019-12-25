# frozen_string_literal: true

module EveryMatrix
  class CategoriesQuery < ::Base::Resolver
    type !types[CategoryType]

    description 'List of casino games'

    argument :kind, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EveryMatrix::Category.where(kind: args['kind'])
    end
  end
end
