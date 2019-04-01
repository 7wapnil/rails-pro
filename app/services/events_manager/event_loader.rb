module EventsManager
  class EventLoader < BaseEntityLoader
    def call
      check_existence!

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

    private

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
