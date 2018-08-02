module Bet
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :amount, !types.Float
    field :odd, !Types::OddType
    field :market, !Types::MarketType
  end
end
