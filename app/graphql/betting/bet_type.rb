module Betting
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :id, !types.ID
    field :amount, !types.Float
    field :currency, !Currencies::CurrencyType
    field :odd, !Types::OddType
    field :market, !Types::MarketType
    field :created_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.created_at.strftime('%e.%m.%y') }
    end
    field :event, Events::EventType
    field :title, Titles::TitleType

    field :oddValue do
      type !types.Float
      resolve ->(obj, _args, _ctx) { obj.odd_value }
    end

    field :message, types.String
    field :status, !types.String
  end
end
