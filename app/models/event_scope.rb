class EventScope < ApplicationRecord
  belongs_to :discipline
  belongs_to :event_scope, optional: true

  validates :name, presence: true

  enum kind: {
    tournament: 0,
    country: 1
  }
end
