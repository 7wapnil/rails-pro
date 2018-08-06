module Betting
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :amount, !types.Float
    field :currency, !types.String
    field :status, !types.String
    field :message, types.String
    field :odd, !Types::OddType
    field :market, !Types::MarketType
  end
end
