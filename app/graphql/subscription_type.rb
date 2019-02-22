# frozen_string_literal: true

SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  # Radar Providers fields
  field SubscriptionFields::PROVIDER_UPDATED, Providers::ProviderType

  # Event fields
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
  field SubscriptionFields::CATEGORY_EVENT_UPDATED, Events::EventType do
    argument :category, types.ID
    argument :live, types.Boolean
  end
  field SubscriptionFields::TOURNAMENT_EVENT_UPDATED, Events::EventType do
    argument :tournament, types.ID
    argument :live, types.Boolean
  end

  # Market fields
  field SubscriptionFields::MARKET_UPDATED, Types::MarketType do
    argument :id, types.ID
  end
  field SubscriptionFields::EVENT_MARKET_UPDATED, Types::MarketType do
    argument :eventId, types.ID
  end
  field SubscriptionFields::CATEGORY_MARKET_UPDATED, Types::MarketType do
    argument :eventId, types.ID
    argument :category, types.String
  end

  # Customer specific fields
  field SubscriptionFields::WALLET_UPDATED,
        Wallets::WalletType,
        subscription_scope: :customer_id
end
