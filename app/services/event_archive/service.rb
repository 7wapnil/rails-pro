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
        name: @event.name,
        description: @event.name,
        start_at: @event.start_at,
        payload: @event.payload
      )
    end

    def archive_scopes!
      @event.event_scopes.each do |scope|
        puts scope.id
        ArchivedEventScope.create!(
          name: scope.name,
          kind: scope.kind,
          archived_event: @archived_event
        )
      end
    end
  end
end
