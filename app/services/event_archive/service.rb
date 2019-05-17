module EventArchive
  class Service < ApplicationService
    def initialize(event:)
      @event = event
    end

    def call
      archive_event!
      archive_scopes!
    end

    private

    def archive_event!
      @archived_event = ArchivedEvent.create!(
        external_id: @event.external_id,
        name: @event.name,
        title_name: @event.title.name,
        description: @event.name,
        start_at: @event.start_at,
        display_status: @event.display_status,
        home_score: @event.home_score,
        away_score: @event.away_score,
        time_in_seconds: @event.time_in_seconds,
        liveodds: @event.liveodds
      )
    end

    def archive_scopes!
      @event.event_scopes.each do |scope|
        ArchivedEventScope.create!(
          external_id: scope.external_id,
          name: scope.name,
          kind: scope.kind,
          archived_event: @archived_event,
          event_scope_external_id: scope.event_scope&.external_id
        )
      end
    end
  end
end
