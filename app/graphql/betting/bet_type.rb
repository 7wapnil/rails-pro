# frozen_string_literal: true

module Betting
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :id, !types.ID
    field :amount, !types.Float
    field :currency, !Currencies::CurrencyType
    field :odd, !Types::OddType
    field :market, !Types::MarketType
    field :createdAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.created_at.strftime('%e.%m.%y') }
    end
    field :event, Events::EventType
    field :title, Titles::TitleType

    field :oddValue do
      type !types.Float
      resolve ->(obj, _args, _ctx) { obj.odd_value }
    end

    field :status, !types.String
    field :message, types.String, property: :human_notification_message
    field :displayStatus, types.String,
          resolve: ->(obj, *) do
            break obj.display_status unless obj.settled?
            break ::StateMachines::BetStateMachine::VOIDED if obj.void_factor

            obj.settlement_status
          end
  end
end
