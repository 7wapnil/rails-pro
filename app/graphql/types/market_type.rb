Types::MarketType = GraphQL::ObjectType.define do
  name 'Market'

  field :id, !types.ID
  field :eventId, !types.ID, property: :event_id
  field :name, !types.String
  field :priority, types.Int
  field :status, types.String
  field :odds, types[Types::OddType], property: :active_odds
  field :visible, types.Boolean
  field :category, types.String
end
