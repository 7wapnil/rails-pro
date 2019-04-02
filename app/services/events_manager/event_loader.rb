module EventsManager
  class EventLoader < BaseEntityLoader
    MATCH_TYPE_REGEXP = /:match:/

    def call
      validate!
      load_event
    end

    private

    def load_event
      event = ::Event.create!(external_id: event_data.id,
                              start_at: event_data.start_at,
                              name: event_data.name,
                              description: event_data.name,
                              traded_live: event_data.traded_live?,
                              payload: event_data.payload,
                              title: title,
                              competitors: competitors)

      event.event_scopes << ScopesBuilder.new(event, event_data).build
      event
    end

    def validate!
      check_support!
      check_existence!
    end

    def check_support!
      is_matching = @external_id.to_s.match?(MATCH_TYPE_REGEXP)
      err_msg = "Event ID '#{@external_id}' is not supported"
      raise NotImplementedError, err_msg unless is_matching
    end

    def check_existence!
      msg = "Event with ID '#{event_data.id}' already exists"
      raise StandardError, msg if ::Event.find_by(external_id: event_data.id)
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
