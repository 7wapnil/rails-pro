# frozen_string_literal: true

module EveryMatrix
  ProviderType = GraphQL::ObjectType.define do
    name 'ProviderType'

    field :id, types.ID do
      resolve ->(obj, *) { "#{obj.model_name.element}:#{obj.id}" }
    end
    field :name, types.String do
      resolve ->(obj, *) { obj.try(:representation_name) || obj.name }
    end
    field :metaDescription, types.String, property: :meta_description
    field :slug, types.String
    field :logoUrl, types.String, property: :logo_url
    field :enabled, types.String
    field :internalImageName, types.String, property: :internal_image_name
  end
end
