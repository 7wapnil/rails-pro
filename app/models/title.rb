# frozen_string_literal: true

class Title < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :external_name

  has_many :events, dependent: :destroy
  has_many :event_scopes, dependent: :destroy
  has_many :tournaments, -> { where kind: EventScope::TOURNAMENT },
           class_name: EventScope.name

  has_many :dashboard_event_scopes, -> { with_dashboard_events },
           class_name: EventScope.name

  has_many :dashboard_tournaments, -> { tournament.with_dashboard_events },
           class_name: EventScope.name

  has_many :betting_limits, dependent: :destroy, inverse_of: :title

  enum kind: {
    esports: ESPORTS = 'esports',
    sports:  SPORTS  = 'sports'
  }

  validates :external_name, :kind, presence: true
  validates :external_name, uniqueness: true

  scope :with_active_events, ->(limit_start_at: nil) {
    joins(:events)
      .merge(Event.active.visible.upcoming(limit_start_at: limit_start_at))
      .or(joins(:events).merge(Event.active.visible.in_play))
      .distinct
  }

  def self.ordered_by_name
    titles_ordering_sql = Arel.sql('LOWER(COALESCE(name, external_name))')
    order(titles_ordering_sql)
  end
end
