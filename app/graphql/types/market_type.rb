Types::MarketType = GraphQL::ObjectType.define do
  name 'Market'

  field :id, !types.ID
  field :name, !types.String
  field :priority, types.Int
  field :status, types.Int do
    resolve ->(obj, _args, _ctx) { Market.statuses[obj.status] }
  end
  field :odds, types[Types::OddType]
end
