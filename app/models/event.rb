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
end
