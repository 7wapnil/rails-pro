module EventsManager
  class ScopesBuilder < ApplicationService
    include EventsManager::Logger

    def initialize(event, event_entity)
      @event = event
      @event_entity = event_entity
    end

    def call
      create_scopes
    end

    private

    def create_scopes
      parent_scope = nil

      scopes_data.each do |scope_data|
        parent_scope = create_scope_and_associate(scope_data[:data],
                                                  scope_data[:kind],
                                                  parent_scope)
      end
    end

    def scopes_data
      [{ data: @event_entity.category, kind: ::EventScope::CATEGORY },
       { data: @event_entity.tournament, kind: ::EventScope::TOURNAMENT },
       { data: @event_entity.season, kind: ::EventScope::SEASON }]
    end

    def create_scope_and_associate(entity, kind, parent_scope = nil)
      if entity.nil?
        Rails.logger.debug "Scope '#{kind}' fixture not found or empty"
        return nil
      end

      create_scope!(entity, kind, parent_scope)
    end

    def create_scope!(entity, kind, parent_scope = nil)
      log :debug, "Scope data: #{entity}, kind: #{kind}"

      scope = ::EventScope.new(external_id: entity.id,
                               name: entity.name,
                               kind: kind,
                               event_scope: parent_scope,
                               title: @event.title)

      ::EventScope.create_or_update_on_duplicate(scope)
      associate_scope(scope)

      scope
    end

    def associate_scope(scope)
      ::ScopedEvent.create_or_update_on_duplicate(
        ::ScopedEvent.new(event: @event, event_scope: scope)
      )
    end
  end
end
