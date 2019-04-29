module EventsManager
  class EventFetcher < BaseEntityLoader
    MATCH_TYPE_REGEXP = /:match:/

    def call
      check_support!
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
      update_associations(event)
      log :info, "Updated event '#{@external_id}'"

      event
    end

    def update_associations(event)
      ScopesBuilder.call(event, event_data)

      competitors.each do |competitor|
        event_competitor = ::EventCompetitor.new(event: event,
                                                 competitor: competitor)
        ::EventCompetitor.create_or_ignore_on_duplicate(event_competitor)
      end
    end

    def check_support!
      return if EventsManager::Entities::Event.type_match?(event_data.id)

      raise NotImplementedError, "Event ID '#{event_data.id}' is not supported"
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
