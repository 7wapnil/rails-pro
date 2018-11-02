class EventScope < ApplicationRecord
  include HasUniqueExternalId

  belongs_to :title
  belongs_to :event_scope, optional: true
  has_many :scoped_events
  has_many :events, through: :scoped_events

  enum kind: {
    tournament: 0,
    country: 1,
    season: 2
  }

  scope :tournaments, -> { where(kind: :tournament) }
  scope :countries, -> { where(kind: :country) }
  scope :seasons, -> { where(kind: :season) }

  validates :name, presence: true
end
