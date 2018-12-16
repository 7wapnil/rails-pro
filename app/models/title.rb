class Title < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :name

  scope :with_active_events_amount, -> {
    select('titles.*')
      .select('count(ae.id) as active_events_amount')
      .joins(['LEFT JOIN events ae ON ae.title_id = titles.id AND ',
              "ae.start_at > #{connection.quote(Event.start_time_offset)} AND ",
              'ae.end_at IS NULL'].join)
      .group('titles.id')
  }
  scope :with_live_events_amount, -> {
    select('titles.*')
      .select('count(le.id) as live_events_amount')
      .joins(['LEFT JOIN events le ON le.title_id = titles.id AND ',
              "le.start_at > #{connection.quote(Event.start_time_offset)} AND ",
              'le.end_at IS NULL AND le.traded_live IS TRUE'].join)
      .group('titles.id')
  }

  has_many :events, dependent: :destroy
  has_many :event_scopes, dependent: :destroy
  has_many :tournaments, -> { where kind: :tournament },
           class_name: 'EventScope'

  enum kind: {
    esports: ESPORTS = 'esports',
    sports:  SPORTS  = 'sports'
  }

  validates :name, :kind, presence: true
  validates :name, uniqueness: true
end
