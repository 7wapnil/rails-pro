SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  field :event_updated, Events::EventType
end
