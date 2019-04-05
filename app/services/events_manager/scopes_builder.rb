module EventsManager
  class ScopesBuilder
    def initialize(event, event_entity)
      @event = event
      @event_entity = event_entity
    end

    def build
      category = find_or_create_scope!(@event_entity.category,
                                       ::EventScope::CATEGORY)
      tournament = find_or_create_scope!(@event_entity.tournament,
                                         ::EventScope::TOURNAMENT,
                                         category)
      season = find_or_create_scope!(@event_entity.season,
                                     ::EventScope::SEASON,
                                     tournament)

      [category, tournament, season]
    end

    private

    def find_or_create_scope!(entity, kind, parent_scope = nil)
      if entity.nil?
        Rails.logger.warn "Scope '#{kind}' fixture is empty"
        return nil
      end

      Rails.logger.debug "Scope data: #{entity}, kind: #{kind}"

      scope = ::EventScope.new(external_id: entity.id,
                               name: entity.name,
                               kind: kind,
                               event_scope: parent_scope,
                               title: @event.title)
      ::EventScope.create_or_update_on_duplicate(scope)
      scope
    end
  end
end
