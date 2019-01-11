module WebSocket
  class Client
    include Singleton

    def trigger_event_update(event)
      ArcanebetSchema.subscriptions.trigger('events_updated', {}, event)
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
      ArcanebetSchema.subscriptions.trigger('kind_event_updated',
                                            { kind: event.title.kind,
                                              live: event.in_play? },
                                            event)
    end

    def trigger_sport_event(event)
      ArcanebetSchema.subscriptions.trigger('sport_event_updated',
                                            { title: event.title_id,
                                              live: event.in_play? },
                                            event)
    end

    def trigger_tournament_event(event)
      ArcanebetSchema.subscriptions.trigger('tournament_event_updated',
                                            { tournament: event.tournament.id,
                                              live: event.in_play? },
                                            event)
    end
  end
end
