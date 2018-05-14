Types::EventType = GraphQL::ObjectType.define do
  name 'Event'

  field :id, !types.ID
  field :name, !types.String
  field :description, !types.String
  field :start_at, types.String do
    resolve ->(obj, _args, _ctx) { obj.start_at&.iso8601 }
  end
  field :end_at, types.String do
    resolve ->(obj, _args, _ctx) { obj.end_at&.iso8601 }
  end
  field :markets, types[Types::MarketType]
end
