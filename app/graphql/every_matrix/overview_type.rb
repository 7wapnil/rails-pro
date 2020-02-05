# frozen_string_literal: true

module EveryMatrix
  OverviewType = GraphQL::ObjectType.define do
    NAME_REGEXP = /(.*)-.*$/

    name 'OverviewType'

    field :id, types.ID
    field :label, types.String
    field :context, types.String
    field :metaDescription, types.String, property: :meta_description
    field :position, types.Int
    field :name, types.String do
      resolve ->(obj, *) { obj.context[NAME_REGEXP, 1] }
    end
    field :playItems, types[PlayItemType] do
      resolve ->(obj, _args, ctx) do
        OverviewLoader.for(PlayItem, ctx[:request]).load(obj.id)
      end
    end
  end
end
