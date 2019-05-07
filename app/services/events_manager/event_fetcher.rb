module EventsManager
  class EventFetcher < BaseEntityLoader
    MATCH_TYPE_REGEXP = /:match:/

    def call
      return unless type_supported?

      load_event
    end

    private

    def load_event
      event = ::Event.new(external_id: event_data.id,
                          start_at: event_data.start_at,
                          name: event_data.name,
                          description: event_data.name,
                          traded_live: event_data.traded_live?,
                          payload: event_data.payload,
                          title: title)
      Event.create_or_update_on_duplicate(event)
      log :info, message: 'Updated event', event_id: @external_id
      update_associations(event)

      event&.reload
    end

    def update_associations(event)
      ScopesBuilder.call(event, event_data)
      log :info, message: 'Event scopes updated', event_id: @external_id

      competitors.each do |competitor|
        event_competitor = ::EventCompetitor.new(event: event,
                                                 competitor: competitor)
        ::EventCompetitor.create_or_ignore_on_duplicate(event_competitor)
      end
    end

    def type_supported?
      return true if EventsManager::Entities::Event.type_match?(event_data.id)

      error_message = I18n.t('errors.messages.unsupported_event_type',
                             event_id: event_data.id)

      log_job_message(:warn, message: error_message, event_id: event_data.id)

      false
    end

    def event_data
      @event_data ||= EventsManager::Entities::Event.new(query)
    end

    def query
      api_client.event_raw(@external_id)
    end

    def title
      ::Title
        .create_with(name: event_data.sport.name)
        .find_or_create_by(external_id: event_data.sport.id)
    end

    def competitors
      event_data.competitors.map do |entity|
        CompetitorLoader.call(entity.id)
      end
    end
  end
end
