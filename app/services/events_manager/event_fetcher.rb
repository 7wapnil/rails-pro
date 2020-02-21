# frozen_string_literal: true

module EventsManager
  class EventFetcher < BaseEntityLoader
    MATCH_TYPE_REGEXP = /:match:/

    def call
      return unless type_supported?

      load_event
    end

    private

    def load_event
      event = ::Event.new(event_attributes)
      Event.create_or_update_on_duplicate(event)
      log :info, message: 'Updated event', event_id: @external_id

      update_competitors(event)

      update_event_scopes(event) if load_associations?
      event.update!(ready: true)

      event
    end

    def load_associations?
      @options[:only_event].blank?
    end

    def update_event_scopes(event)
      ScopesBuilder.call(event, event_data)
      log :info, message: 'Event scopes updated', event_id: @external_id
    end

    def update_competitors(event)
      event.event_competitors.delete_all

      competitors.each do |competitor|
        ::EventCompetitor.create(
          event: event,
          competitor: competitor,
          qualifier: competitor_qualifier(competitor)
        )
      end
    end

    def type_supported?
      return true if EventsManager::Entities::Event.type_match?(event_data.id)

      log_job_message(
        :warn,
        message: I18n.t('internal.errors.messages.unsupported_event_type'),
        event_id: event_data.id
      )

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

    def event_attributes
      {
        external_id: event_data.id,
        start_at: event_data.start_at,
        twitch_start_time: event_data.start_at,
        twitch_end_time: expected_event_end_time,
        name: event_data.name,
        description: event_data.name,
        traded_live: event_data.traded_live?,
        liveodds: event_data.liveodds,
        title: title
      }
    end

    def expected_event_end_time
      return unless event_data.start_at

      event_data.start_at.to_time + Event::TWITCH_END_TIME_DELAY
    end

    def competitor_qualifier(competitor)
      event_data
        .competitors
        .find { |entity| entity.id == competitor.external_id }
        .qualifier
    end
  end
end
