# frozen_string_literal: true

module WebSocket
  class Client
    include Singleton

    def trigger_event_update(event, profiler: nil)
      profiler.log_state(:web_socket_emit_initiated_at)
      profiled_event = { data: event, profiler: profiler }

      trigger(SubscriptionFields::EVENTS_UPDATED, profiled_event)
      trigger(SubscriptionFields::EVENT_UPDATED, event, id: event.id)

      return unless event_available?(event)

      trigger_kind_event(profiled_event)
      trigger_sport_event(event)
      trigger_category_event(event)
      trigger_tournament_event(event)
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

    def trigger_wallet_update(wallet)
      trigger(SubscriptionFields::WALLET_UPDATED,
              wallet,
              {},
              wallet.customer_id)
    end

    def trigger_bet_update(bet)
      trigger(SubscriptionFields::BET_UPDATED,
              bet,
              { id: bet.id },
              bet.customer_id)
    end

    private

    def trigger(name, object, args = {}, scope = nil)
      ArcanebetSchema.subscriptions.trigger(name, args, object, scope: scope)
    end

    def event_available?(event)
      event.active? && event.visible?
    end

    def trigger_kind_event(profiled_event)
      event = profiled_event[:data]
      return warn("Event ID #{event.id} has no title") unless event.title

      trigger(
        SubscriptionFields::KIND_EVENT_UPDATED,
        profiled_event,
        kind: event.title.kind
      )
    end

    def trigger_sport_event(event)
      return unless event.title_id

      trigger(
        SubscriptionFields::SPORT_EVENT_UPDATED,
        event,
        title: event.title_id
      )
    end

    def trigger_category_event(event)
      return unless event.category

      trigger(
        SubscriptionFields::CATEGORY_EVENT_UPDATED,
        event,
        category: event.category.id
      )
    end

    def trigger_tournament_event(event)
      return warn("Event #{event.id} has no tournament") unless event.tournament

      trigger(
        SubscriptionFields::TOURNAMENT_EVENT_UPDATED,
        event,
        tournament: event.tournament.id
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

    def warn(msg)
      Rails.logger.warn(msg)
    end
  end
end
