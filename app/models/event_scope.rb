# frozen_string_literal: true

class EventScope < ApplicationRecord
  include Importable
  include BetterSluggable

  conflict_target :external_id
  conflict_updatable :name

  friendly_id :name, use: :sequentially_slugged

  belongs_to :title
  belongs_to :event_scope, optional: true
  has_many :scoped_events
  has_many :events, through: :scoped_events
  has_many :event_scopes

  enum kind: {
    tournament: TOURNAMENT = 'tournament',
    category: CATEGORY = 'category',
    season: SEASON = 'season'
  }

  validates :name, presence: true

  def self.with_dashboard_events
    joins(:events)
      .merge(Event.active.visible.upcoming)
      .or(joins(:events).merge(Event.active.visible.in_play))
      .distinct
      .order('event_scopes.kind, event_scopes.position')
  end
end
