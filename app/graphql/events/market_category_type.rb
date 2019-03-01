module Events
  MarketCategoryType = GraphQL::ObjectType.define do
    name 'MarketCategory'

    field :id, !types.ID
    field :name, !types.String
    field :count, !types.Int
  end
end
