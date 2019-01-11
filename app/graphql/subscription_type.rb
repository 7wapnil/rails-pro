SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  field :events_updated, Events::EventType

  field :kind_event_updated, Events::EventType do
    argument :kind, types.String
    argument :live, types.Boolean
  end
  field :sport_event_updated, Events::EventType do
    argument :title, types.ID
    argument :live, types.Boolean
  end
  field :tournament_event_updated, Events::EventType do
    argument :tournament, types.ID
    argument :live, types.Boolean
  end
end
