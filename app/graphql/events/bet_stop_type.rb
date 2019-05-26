# frozen_string_literal: true

module Events
  BetStopType = GraphQL::ObjectType.define do
    name 'BetStop'

    field :eventId, !types.ID, property: :event_id
    field :marketStatus, types.String, property: :market_status
  end
end
