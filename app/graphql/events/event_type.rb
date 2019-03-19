# frozen_string_literal: true

module Events
  EventType = GraphQL::ObjectType.define do
    name 'Event'

    field :id, !types.ID
    field :name, !types.String
    field :description, !types.String
    field :status, !types.String
    field :competitors, !types[Events::EventCompetitorType] do
      resolve ->(obj, _args, _ctx) { obj.details.competitors }
    end
    field :markets, function: MarketsQuery.new

    field :priority, !types.Int
    field :visible, !types.Boolean
    field :title, Titles::TitleType

    field :start_status, Events::StartStatusEnum

    field :start_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.start_at&.iso8601 }
    end

    field :end_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.end_at&.iso8601 }
    end

    field :scopes, types[Types::ScopeType] do
      resolve ->(obj, _args, _ctx) { obj.event_scopes }
    end

    field :tournament, Types::ScopeType

    field :markets_count, !types.Int do
      resolve ->(obj, _args, _ctx) do
        obj.dashboard_markets.size
      end
    end

    field :dashboard_market, Types::MarketType do
      resolve ->(obj, _args, _ctx) do
        EventMarketsLoader.for(Market).load(obj.id)
      end
    end
    field :state, Types::EventStateType

    field :categories, !types[Events::MarketCategoryType]
  end
end
