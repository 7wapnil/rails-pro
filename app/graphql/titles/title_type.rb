module Titles
  TitleType = GraphQL::ObjectType.define do
    name 'Title'

    field :id, !types.ID
    field :name, !types.String
    field :kind, !types.String
    field :eventsAmount, !types.Int do
      resolve ->(obj, _args, _ctx) { obj.active_events_amount }
    end
    field :hasLive, !types.Boolean do
      resolve ->(obj, _args, _ctx) { obj.live_events_amount.positive? }
    end
    field :tournaments, types[Types::ScopeType]
  end
end
