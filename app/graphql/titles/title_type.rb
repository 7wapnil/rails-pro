module Titles
  TitleType = GraphQL::ObjectType.define do
    name 'Title'

    field :id, !types.ID
    field :name, !types.String
    field :kind, !types.String

    field :tournaments, types[Types::ScopeType] do
      resolve ->(obj, _args, _ctx) { obj.tournaments.active }
    end
  end
end
