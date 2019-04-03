module EventsManager
  class EventLoader < BaseEntityLoader
    MATCH_TYPE_REGEXP = /:match:/

    def call
      validate! unless @options[:skip_validation]
      load_event
    end

    private

    def validate!
      check_support!
      check_existence! if @options[:check_existence]
    end

    def load_event
      event = ::Event.new(external_id: event_data.id,
                          start_at: event_data.start_at,
                          name: event_data.name,
                          description: event_data.name,
                          traded_live: event_data.traded_live?,
                          payload: event_data.payload,
                          title: title)

      build_associations(event)
      Event.create_or_update_on_duplicate(event)
      event
    end

    def build_associations(event)
      ScopesBuilder.new(event, event_data).build.each do |scope|
        event.scoped_events.build(event_scope: scope)
      end

      competitors.each do |competitor|
        event.event_competitors.build(competitor: competitor)
      end
    end

    def check_support!
      return if @external_id.to_s.match?(MATCH_TYPE_REGEXP)

      raise NotImplementedError, "Event ID '#{@external_id}' is not supported"
    end

    def check_existence!
      return unless ::Event.exists?(external_id: event_data.id)

      raise StandardError, "Event with ID '#{event_data.id}' already exists"
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
