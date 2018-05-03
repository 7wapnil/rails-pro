class Event < ApplicationRecord
  KINDS = {
    match: 'match',
    tournament: 'tournament'
  }.freeze

  belongs_to :discipline
  belongs_to :event, optional: true
  has_many :markets

  validates :kind, :name, presence: true
  validates :kind, inclusion: { in: KINDS.values }

  scope :match, -> { where(kind: KINDS[:match]) }
  scope :tournament, -> { where(kind: KINDS[:tournament]) }

  def self.in_play
    match.where('start_at < ? AND end_at IS NULL', Time.zone.now)
  end
end
