# There are resolvers added to every enpoint
# to reload models, because we faced with some outdated
# data sending problem
#
# @todo Find the source of problem and fix it better way
#
SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  # Radar Providers fields
  field SubscriptionFields::PROVIDER_UPDATED, Providers::ProviderType do
    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end

  # Event fields
  field SubscriptionFields::EVENT_UPDATED, Events::EventType do
    argument :id, types.ID
    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end

  field SubscriptionFields::EVENTS_UPDATED, Events::EventType do
    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end

  field SubscriptionFields::KIND_EVENT_UPDATED, Events::EventType do
    argument :kind, types.String
    argument :live, types.Boolean

    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end
  field SubscriptionFields::SPORT_EVENT_UPDATED, Events::EventType do
    argument :title, types.ID
    argument :live, types.Boolean

    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end
  field SubscriptionFields::TOURNAMENT_EVENT_UPDATED, Events::EventType do
    argument :tournament, types.ID
    argument :live, types.Boolean

    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end

  # Market fields
  field SubscriptionFields::MARKET_UPDATED, Types::MarketType do
    argument :id, types.ID

    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end
  field SubscriptionFields::EVENT_MARKET_UPDATED, Types::MarketType do
    argument :eventId, types.ID

    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end
  field SubscriptionFields::CATEGORY_MARKET_UPDATED, Types::MarketType do
    argument :eventId, types.ID
    argument :category, types.String

    resolve ->(obj, _args, _ctx) { obj.reload if obj }
  end

  # Customer specific fields
  field SubscriptionFields::WALLET_UPDATED,
        Wallets::WalletType,
        subscription_scope: :customer_id do
          resolve ->(obj, _args, _ctx) { obj.reload if obj }
        end
end
