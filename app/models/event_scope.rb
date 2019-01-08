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

  def self.with_dashboard_events
    joins(:events)
      .merge(Event.active.visible.upcoming)
      .or(joins(:events).merge(Event.active.visible.in_play))
      .distinct
  end
end
