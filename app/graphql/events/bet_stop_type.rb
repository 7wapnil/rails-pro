# frozen_string_literal: true

module Events
  BetStopType = GraphQL::ObjectType.define do
    name 'BetStop'

    field :event_id, !types.ID
    field :market_status, types.String
  end
end
