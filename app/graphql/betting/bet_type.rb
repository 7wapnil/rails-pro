# frozen_string_literal: true

module Betting
  BetType = GraphQL::ObjectType.define do
    name 'Bet'

    field :id, !types.ID
    field :amount, !types.Float
    field :currency, !Currencies::CurrencyType
    field :betLegs, types[BetLegType], property: :bet_legs

    field :createdAt, types.String do
      resolve ->(obj, _args, _ctx) do
        obj.created_at.strftime('%e.%m.%y %H:%M:%S')
      end
    end
    field :oddValue, !types.Float, property: :odd_value
    field :status, !types.String
    field :notificationCode, types.String, property: :notification_code
    field :message, types.String, property: :human_notification_message
    field :displayStatus, types.String, property: :display_status
  end
end
