# frozen_string_literal: true

module EveryMatrix
  PlayItemType = GraphQL::ObjectType.define do
    name 'PlayItemType'

    field :id, types.String, property: :external_id
    field :name, types.String do
      resolve ->(obj, *) { obj.name || obj.short_name }
    end
    field :description, types.String
    field :url, types.String
    field :shortName, types.String, property: :short_name
    field :logoUrl, types.String, property: :thumbnail_url
    field :backgroundImageUrl, types.String, property: :background_image_url
  end
end
