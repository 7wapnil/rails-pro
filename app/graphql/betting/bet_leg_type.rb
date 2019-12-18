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

    field :eventEnabled, types.Boolean, property: :event_available?

    field :marketStatus, types.String, property: :market_status
    field :marketVisible, types.String, property: :market_visible?
    field :marketEnabled, types.Boolean, property: :market_enabled?

    field :oddId, !types.ID, property: :odd_id
    field :oddValue, !types.Float, property: :odd_value
    field :oddEnabled, types.Boolean, property: :odd_active?

    field :displayStatus, types.String, property: :display_status
    field :notificationCode, types.String, property: :notification_code
    field :message, types.String, property: :human_notification_message
  end
end
