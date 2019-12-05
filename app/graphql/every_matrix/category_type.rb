# frozen_string_literal: true

module EveryMatrix
  CategoryType = GraphQL::ObjectType.define do
    name 'CategoryType'

    NAME_REGEXP = /(.*)-.*$/

    field :id, types.ID
    field :label, types.String
    field :context, types.String
    field :name, types.String do
      resolve ->(obj, *) { obj.context[NAME_REGEXP, 1] }
    end
    field :position, types.Int
  end
end
