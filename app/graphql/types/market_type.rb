Types::MarketType = GraphQL::ObjectType.define do
  name 'Market'

  field :id, !types.ID
  field :name, !types.String
  field :priority, types.Int
end
