# frozen_string_literal: true

module EveryMatrix
  CategoryType = GraphQL::ObjectType.define do
    name 'CategoryType'

    field :id, types.ID
    field :label, types.String
    field :context, types.String
    field :metaTitle, types.String, property: :meta_title
    field :metaDescription, types.String, property: :meta_description
    field :position, types.Int
  end
end
