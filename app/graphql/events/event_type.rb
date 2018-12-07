module Events
  EventType = GraphQL::ObjectType.define do
    name 'Event'

    field :id, !types.ID
    field :name, !types.String
    field :description, !types.String
    field :details, Events::EventDetailsType
    field :priority, !types.Int
    field :visible, !types.Boolean

    field :live, types.Boolean do
      resolve ->(obj, _args, _ctx) { obj.traded_live }
    end

    field :title_name, types.String do
      resolve ->(obj, _args, _ctx) { obj.title_name }
    end

    field :start_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.start_at&.iso8601 }
    end

    field :end_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.end_at&.iso8601 }
    end

    field :scopes, types[Types::ScopeType] do
      resolve ->(obj, _args, _ctx) { obj.event_scopes }
    end

    field :tournament, Types::ScopeType
    field :markets, function: Events::MarketsQuery.new
    field :state, Types::EventStateType
  end
end
