class Discipline < ApplicationRecord
  has_many :events, dependent: :destroy

  validates :name, :kind, presence: true
end
