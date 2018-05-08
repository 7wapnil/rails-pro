class EventScope < ApplicationRecord
  belongs_to :discipline
  belongs_to :event_scope, optional: true
  has_many :scoped_events
  has_many :events, through: :scoped_events

  enum kind: {
    tournament: 0,
    country: 1
  }

  validates :name, presence: true
end
