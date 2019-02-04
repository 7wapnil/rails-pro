class ScopedEvent < ApplicationRecord
  belongs_to :event_scope
  belongs_to :event

  validates :event_scope_id, uniqueness: { scope: :event_id }

  def self.tournament
    joins(:event_scope)
      .where(event_scopes: { kind: EventScope::TOURNAMENT })
  end
end
