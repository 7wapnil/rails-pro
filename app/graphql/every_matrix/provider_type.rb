# frozen_string_literal: true

module EveryMatrix
  ProviderType = GraphQL::ObjectType.define do
    name 'ProviderType'

    field :id, types.ID
    field :name, types.String
    field :logoUrl, types.String, property: :logo_url
    field :enabled, types.String
    field :representationName, types.String, property: :representation_name
  end
end
