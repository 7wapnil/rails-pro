module Events
  EventDetailsType = GraphQL::ObjectType.define do
    name 'EventDetails'

    field :competitors, !types[Events::EventCompetitorType]
  end
end
