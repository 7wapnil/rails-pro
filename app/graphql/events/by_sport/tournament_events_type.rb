# frozen_string_literal: true

module Events
  module BySport
    TournamentEventsType = GraphQL::ObjectType.define do
      name 'TournamentEvent'

      field :upcoming, types[::Events::EventType]
      field :live,     types[::Events::EventType]
    end
  end
end
