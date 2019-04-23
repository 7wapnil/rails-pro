module EventsManager
  class EventLoader < BaseEntityLoader
    MATCH_TYPE_REGEXP = /:match:/

    def call
      validate! unless @options[:skip_validation]

      ActiveRecord::Base.transaction do
        event = create_event!
        update_associations(event)
        event
      end
    end

    private

    def validate!
      check_support!
      check_existence! if @options[:check_existence]
    end

    def create_event!
      event = ::Event.new(external_id: event_data.id,
                          start_at: event_data.start_at,
                          name: event_data.name,
                          description: event_data.name,
                          traded_live: event_data.traded_live?,
                          payload: event_data.payload,
                          title: title)

      Event.create_or_update_on_duplicate(event)
      event
    end

    def update_associations(event)
      ScopesBuilder.new(event, event_data).build.each do |scope|
        update_scope(event, scope)
      end

      competitors.compact.each do |competitor|
        update_competitor(event, competitor)
      end
    end

    def update_scope(event, scope)
      return if event.event_scopes.exists?(scope.id)

      event.event_scopes << scope
    end

    def update_competitor(event, competitor)
      return if event.competitors.exists?(competitor.id)

      event.competitors << competitor
    end

    def check_support!
      return if EventsManager::Entities::Event.type_match?(event_data.id)

      raise NotImplementedError, "Event ID '#{event_data.id}' is not supported"
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
