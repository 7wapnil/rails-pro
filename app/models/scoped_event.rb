class ScopedEvent < ApplicationRecord
  belongs_to :event_scope
  belongs_to :event

  validates :event_scope_id, uniqueness: { scope: :event_id }
end
