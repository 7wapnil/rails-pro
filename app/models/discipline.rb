class Discipline < ApplicationRecord
  has_many :events, dependent: :destroy

  enum kind: {
    esports: 0,
    sports: 1
  }

  validates :name, presence: true
end
