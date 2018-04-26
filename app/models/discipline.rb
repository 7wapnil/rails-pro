class Discipline < ApplicationRecord
  KINDS = {
    match: 'match',
    tournament: 'tournament'
  }.freeze

  has_many :events, dependent: :destroy

  validates :name, :kind, presence: true
  validates :kind, inclusion: { in: KINDS.values }
end
