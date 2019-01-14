module WebSocket
  class Client
    include Singleton

    def trigger_event_update(event)
      ArcanebetSchema.subscriptions.trigger(SubscriptionFields::EVENTS_UPDATED,
                                            {},
                                            event)
      ArcanebetSchema.subscriptions.trigger(SubscriptionFields::EVENT_UPDATED,
                                            { id: event.id },
                                            event)
      trigger_kind_event event
      trigger_sport_event event
      trigger_tournament_event event
    end

    def emit!(event, data = {})
      Rails.logger.debug "Sending websocket event '#{event}', data: #{data}"
      message = ActiveSupport::JSON.encode(event: event, data: data)
      connection.publish(channel_name, message)
    end

    def emit(event, data = {})
      emit!(event, data)
    rescue StandardError => e
      Rails.logger.error e.message
      false
    end

    def connection
      @connection ||= Redis.new(url: ENV['REDIS_URL'])
    end

    def reset_connection
      @connection = nil
    end

    def channel_name
      'events'
    end

    private

    def trigger_kind_event(event)
      ArcanebetSchema.subscriptions.trigger(
        SubscriptionFields::KIND_EVENT_UPDATED,
        { kind: event.title.kind,
          live: event.in_play? },
        event
      )
    end

    def trigger_sport_event(event)
      ArcanebetSchema.subscriptions.trigger(
        SubscriptionFields::SPORT_EVENT_UPDATED,
        { title: event.title_id,
          live: event.in_play? },
        event
      )
    end

    def trigger_tournament_event(event)
      ArcanebetSchema.subscriptions.trigger(
        SubscriptionFields::TOURNAMENT_EVENT_UPDATED,
        { tournament: event.tournament&.id,
          live: event.in_play? },
        event
      )
    end
  end
end
