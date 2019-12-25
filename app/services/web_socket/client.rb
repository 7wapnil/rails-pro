# frozen_string_literal: true

module WebSocket
  class Client
    include Singleton
    include JobLogger

    def trigger_event_update(event, force: false)
      trigger(SubscriptionFields::EVENTS_UPDATED, event)
      trigger(SubscriptionFields::EVENT_UPDATED, event, id: event.id)

      return unless event_available?(event) || force

      trigger_tournament_event(event)
      trigger_category_event(event)
      trigger_sport_event(event)
      trigger_kind_event(event)
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
              bet.decorate,
              { id: bet.id },
              bet.customer_id)
    end

    def trigger_event_bet_stop(event, market_status)
      message = OpenStruct.new(event_id: event.id, market_status: market_status)

      trigger(SubscriptionFields::EVENTS_BET_STOPPED, message)
      trigger(SubscriptionFields::EVENT_BET_STOPPED, message, id: event.id)
    end

    def trigger_mts_connection_status_update(application_status)
      trigger(SubscriptionFields::MTS_CONNECTION_STATUS_UPDATED,
              application_status)
    end

    def trigger_categories_update(category)
      trigger(SubscriptionFields::CATEGORIES_UPDATED,
              category, kind: category.kind)
    end

    private

    def trigger(name, object, args = {}, scope = nil)
      ArcanebetSchema.subscriptions.trigger(name, args, object, scope: scope)
    end

    def event_available?(event)
      event.active? && event.visible?
    end

    def trigger_kind_event(event)
      return warn('Event has no title', event) unless event.title

      return unless event.upcoming_for_time? || event.in_play?

      trigger(
        SubscriptionFields::KIND_EVENT_UPDATED,
        event,
        kind: event.title.kind
      )
    end

    def trigger_sport_event(event)
      return unless event.title_id &&
                    (event.upcoming_for_time? || event.in_play?)

      trigger(
        SubscriptionFields::SPORT_EVENT_UPDATED,
        event,
        title: event.title_id
      )
    end

    def trigger_category_event(event)
      return unless event.category && category_updatable?(event)

      trigger(
        SubscriptionFields::CATEGORY_EVENT_UPDATED,
        event,
        category: event.category.id
      )
    end

    def trigger_tournament_event(event)
      return warn('Event has no tournament', event) unless event.tournament

      trigger(
        SubscriptionFields::TOURNAMENT_EVENT_UPDATED,
        event,
        tournament: event.tournament.id
      )
    end

    def warn(message, event)
      log_job_message(:warn, message: message, event_id: event.id)
    end

    def category_updatable?(event)
      return unless event.tournament

      tournament_events(event).exists?(id: event.id)
    end

    def tournament_events(event)
      event.tournament
           .events
           .order(:priority, :start_at)
           .limit(Event::UPCOMING_LIMIT)
    end
  end
end
