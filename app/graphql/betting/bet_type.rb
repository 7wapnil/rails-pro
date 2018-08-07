module Betting
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :id, !types.ID
    field :amount, !types.Float
    field :currency, !types.String
    field :odd, !Types::OddType
    field :market, !Types::MarketType
    field :oddValue, !types.Float
    field :message, types.String
    field :status, !types.String
  end
end
