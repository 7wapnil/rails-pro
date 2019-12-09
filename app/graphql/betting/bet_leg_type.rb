# frozen_string_literal: true

module Betting
  BetLegType = GraphQL::ObjectType.define do
    name 'BetLeg'

    field :id, !types.ID
    field :odd, !Types::OddType
    field :market, !Types::MarketType
    field :event, Events::EventType
    field :title, Titles::TitleType

    field :createdAt, types.String do
      resolve ->(obj, _args, _ctx) do
        obj.created_at.strftime('%e.%m.%y %H:%M:%S')
      end
    end

    field :oddId, !types.ID, property: :odd_id
    field :oddValue, !types.Float, property: :odd_value

    field :displayStatus, types.String, property: :display_status
    field :notificationCode, types.String, property: :notification_code
    field :message, types.String, property: :human_notification_message
  end
end
