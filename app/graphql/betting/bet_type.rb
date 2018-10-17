module Betting
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :id, !types.ID
    field :amount, !types.Float
    field :currency, !Wallets::CurrencyType
    field :odd, !Types::OddType
    field :market, !Types::MarketType
    field :created_at, types.String
    # field :event, !Types::EventType

    field :oddValue do
      type !types.Float
      resolve ->(obj, _args, _ctx) { obj.odd_value }
    end

    field :message, types.String
    field :status, !types.String
  end
end
