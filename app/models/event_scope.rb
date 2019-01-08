# frozen_string_literal: true

class EventScope < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :name

  belongs_to :title
  belongs_to :event_scope, optional: true
  has_many :scoped_events
  has_many :events, through: :scoped_events

  enum kind: {
    tournament: TOURNAMENT = 'tournament',
    country:    COUNTRY    = 'country',
    season:     SEASON     = 'season'
  }

  validates :name, presence: true

  scope :active, -> { eager_load(:events).where(events: { active: true }) }
end
