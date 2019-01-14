SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  field SubscriptionFields::EVENT_UPDATED, Events::EventType do
    argument :id, types.ID
  end

  field SubscriptionFields::EVENTS_UPDATED, Events::EventType

  field SubscriptionFields::KIND_EVENT_UPDATED, Events::EventType do
    argument :kind, types.String
    argument :live, types.Boolean
  end
  field SubscriptionFields::SPORT_EVENT_UPDATED, Events::EventType do
    argument :title, types.ID
    argument :live, types.Boolean
  end
  field SubscriptionFields::TOURNAMENT_EVENT_UPDATED, Events::EventType do
    argument :tournament, types.ID
    argument :live, types.Boolean
  end
end
