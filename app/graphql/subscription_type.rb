# frozen_string_literal: true

SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  # Application status
  field SubscriptionFields::MTS_CONNECTION_STATUS_UPDATED,
        Mts::ConnectionStatusType

  # Radar Providers fields
  field SubscriptionFields::PROVIDER_UPDATED, Providers::ProviderType

  # Event fields
  field SubscriptionFields::EVENT_UPDATED, Events::EventType do
    argument :id, types.ID
  end

  field SubscriptionFields::EVENTS_BET_STOPPED, Events::BetStopType
  field SubscriptionFields::EVENT_BET_STOPPED, Events::BetStopType do
    argument :id, types.ID
  end

  field SubscriptionFields::EVENTS_UPDATED, Events::EventType

  field SubscriptionFields::KIND_EVENT_UPDATED, Events::EventType do
    argument :kind, types.String
  end
  field SubscriptionFields::SPORT_EVENT_UPDATED, Events::EventType do
    argument :title, types.ID
  end
  field SubscriptionFields::CATEGORY_EVENT_UPDATED, Events::EventType do
    argument :category, types.ID
  end
  field SubscriptionFields::TOURNAMENT_EVENT_UPDATED, Events::EventType do
    argument :tournament, types.ID
  end

  # Customer specific fields
  field SubscriptionFields::WALLET_UPDATED,
        Wallets::WalletType,
        subscription_scope: :customer_id

  field SubscriptionFields::BET_UPDATED,
        Betting::BetType,
        subscription_scope: :customer_id do
    argument :id, types.ID
  end

  field SubscriptionFields::CATEGORIES_UPDATED, EveryMatrix::CategoryType do
    argument :kind, types.String
    argument :device, types.String
  end
end
