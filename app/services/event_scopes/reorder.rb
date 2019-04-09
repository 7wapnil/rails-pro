module EventScopes
  class Reorder < ApplicationService
    def initialize(sorted_event_scopes)
      @sorted_event_scopes = sorted_event_scopes
    end

    def call
      EventScope.transaction do
        update_event_scopes_order(@sorted_event_scopes)
      end
    end

    private

    def update_event_scopes_order(ids)
      ids.each_with_index do |id, position|
        EventScope.where(id: id).update_all(position: position)
      end
    end
  end
end
