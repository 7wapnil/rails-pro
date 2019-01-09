module Titles
  TitleType = GraphQL::ObjectType.define do
    name 'Title'

    field :id, !types.ID
    field :name, !types.String
    field :kind, !types.String
    field :event_scopes, !types[Types::ScopeType]

    field :tournaments, types[Types::ScopeType] do
      resolve ->(obj, _args, _ctx) { obj.tournaments.with_dashboard_events }
    end
  end
end
