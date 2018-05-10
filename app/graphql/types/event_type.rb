Types::EventType = GraphQL::ObjectType.define do
  name 'Event'

  field :id, !types.ID
  field :name, !types.String
  field :description, !types.String
  field :start_at, types.String
  field :end_at, types.String
  field :markets, types[Types::MarketType]
end
