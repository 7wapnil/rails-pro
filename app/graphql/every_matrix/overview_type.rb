# frozen_string_literal: true

module EveryMatrix
  OverviewType = GraphQL::ObjectType.define do
    name 'OverviewType'

    field :id, types.ID
    field :label, types.String
    field :context, types.String
    field :position, types.Int
    field :playItems, types[PlayItemType] do
      resolve ->(obj, _args, ctx) do
        OverviewLoader
          .for(PlayItem, ctx[:request].location.country_code.upcase)
          .load(obj.id)
      end
    end
  end
end
