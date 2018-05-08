class ScopedEvent < ApplicationRecord
  belongs_to :event_scope
  belongs_to :event
end
