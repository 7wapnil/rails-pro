class EventScope < ApplicationRecord
  belongs_to :title
  belongs_to :event_scope, optional: true
  has_many :scoped_events
  has_many :events, through: :scoped_events

  enum kind: {
    tournament: 0,
    country: 1,
    season: 2
  }

  validates :name, presence: true
end
