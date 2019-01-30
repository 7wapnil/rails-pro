module WebSocket
  class Client
    include Singleton

    def trigger_event_update(event)
      trigger(SubscriptionFields::EVENTS_UPDATED, event)
      trigger(SubscriptionFields::EVENT_UPDATED, event, id: event.id)

      trigger_kind_event event
      trigger_sport_event event
      trigger_tournament_event event
    end

    def trigger_market_update(market)
      trigger(SubscriptionFields::MARKET_UPDATED,
              market,
              id: market.id)
      trigger_event_market(market)
      trigger_category_market(market)
    end

    def trigger_provider_update(provider)
      trigger(SubscriptionFields::PROVIDER_UPDATED, provider)
    end

    private

    def trigger(name, object, args = {}, scope = nil)
      ArcanebetSchema.subscriptions.trigger(name, args, object, scope: scope)
    end

    def trigger_kind_event(event)
      trigger(
        SubscriptionFields::KIND_EVENT_UPDATED,
        event,
        kind: event.title.kind, live: event.in_play?
      )
    end

    def trigger_sport_event(event)
      trigger(
        SubscriptionFields::SPORT_EVENT_UPDATED,
        event,
        title: event.title_id, live: event.in_play?
      )
    end

    def trigger_tournament_event(event)
      trigger(
        SubscriptionFields::TOURNAMENT_EVENT_UPDATED,
        event,
        tournament: event.tournament&.id, live: event.in_play?
      )
    end

    def trigger_event_market(market)
      trigger(
        SubscriptionFields::EVENT_MARKET_UPDATED,
        market,
        eventId: market.event_id
      )
    end

    def trigger_category_market(market)
      trigger(
        SubscriptionFields::CATEGORY_MARKET_UPDATED,
        market,
        eventId: market.event_id, category: market.category
      )
    end
  end
end
