# frozen_string_literal: true

module EveryMatrix
  CategoryType = GraphQL::ObjectType.define do
    name 'CategoryType'

    field :id, types.ID
    field :label, types.String
    field :context, types.String, property: :name
    field :position, types.Int
  end
end
