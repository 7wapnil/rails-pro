# frozen_string_literal: true

module EveryMatrix
  ProviderType = GraphQL::ObjectType.define do
    name 'ProviderType'

    field :id, types.ID
    field :name, types.String
    field :metaDescription, types.String, property: :meta_description
    field :slug, types.String
    field :logoUrl, types.String
    field :enabled, types.String
    field :internalImageName, types.String
  end
end
