module EventScopes
  class CollectChildren < ApplicationService
    def initialize(title_id, event_scope_id = nil)
      @title_id = title_id
      @event_scope_id = event_scope_id
    end

    def call
      {
        name: event_scope&.name || title.name,
        event_scopes: event_scope_children_map
      }.to_json
    end

    private

    def title
      @title ||= Title.find(@title_id)
    end

    def event_scope
      @event_scope ||= if @event_scope_id
                         title.event_scopes.find(@event_scope_id)
                       end
    end

    def event_scope_children
      children = if event_scope
                   event_scope.event_scopes
                 else
                   title.event_scopes.where(event_scope_id: nil)
                 end

      children.includes(:event_scopes).order(:position, :name)
    end

    def event_scope_children_map
      event_scope_children.map do |event_scope_child|
        hash = {
          id: event_scope_child.id,
          name: event_scope_child.name,
          kind: event_scope_child.kind
        }

        event_scope_child.event_scopes.empty? || hash[:has_children] = true

        hash
      end
    end
  end
end
