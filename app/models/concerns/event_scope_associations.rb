# frozen_string_literal: true

module EventScopeAssociations
  extend ActiveSupport::Concern

  EVENT_SCOPE_NAMES = EventScope.kinds.keys

  included do
    EVENT_SCOPE_NAMES.each do |kind|
      # has_one :tournament_scoped_event
      # has_one :category_scoped_event
      # has_one :season_scoped_event
      has_one "#{kind}_scoped_event".to_sym,
              -> { joins(:event_scope).where(event_scopes: { kind: kind }) },
              class_name: ScopedEvent.name

      # has_one :tournament
      # has_one :category
      # has_one :season
      has_one kind.to_sym,
              through: "#{kind}_scoped_event".to_sym,
              class_name: EventScope.name,
              source: :event_scope
    end
  end
end
