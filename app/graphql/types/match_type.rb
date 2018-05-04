Types::MatchType = GraphQL::ObjectType.define do
  name 'Match'

  field :id, !types.ID
  field :name, !types.String
  field :start_at, types.String
  field :end_at, types.String
  field :markets, types[Types::MarketType]
end
