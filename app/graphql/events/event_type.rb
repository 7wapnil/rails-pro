# frozen_string_literal: true

module Events
  EventType = GraphQL::ObjectType.define do
    name 'Event'

    field :id, !types.ID
    field :name, !types.String
    field :description, !types.String
    field :status, !types.String
    field :displayStatus, types.String,
          property: :display_status
    field :score, types.String
    field :timeInSeconds, types.Int,
          property: :time_in_seconds
    field :competitors, !types[Events::EventCompetitorType]
    field :markets, function: MarketsQuery.new

    field :priority, !types.Int
    field :visible, !types.Boolean
    field :title, Titles::TitleType

    field :startStatus, Events::StartStatusEnum,
          property: :start_status

    field :startAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.start_at&.iso8601 }
    end

    field :endAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.end_at&.iso8601 }
    end

    field :scopes, types[Types::ScopeType] do
      resolve ->(obj, _args, _ctx) { obj.event_scopes }
    end

    field :tournament, Types::ScopeType

    field :marketsCount, !types.Int do
      resolve ->(obj, _args, _ctx) do
        obj.dashboard_markets.size
      end
    end

    field :dashboardMarket, Types::MarketType do
      resolve ->(obj, _args, _ctx) do
        EventMarketsLoader.for(Market).load(obj.id)
      end
    end

    field :categories, !types[Events::MarketCategoryType]
  end
end
