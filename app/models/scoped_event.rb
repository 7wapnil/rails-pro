class ScopedEvent < ApplicationRecord
  @auditable = false

  belongs_to :event_scope
  belongs_to :event

  def auditable?
    false
  end
end
