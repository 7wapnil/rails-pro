class Title < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :event_scopes, dependent: :destroy

  enum kind: {
    esports: 0,
    sports: 1
  }

  validates :name, :kind, presence: true
  validates :name, uniqueness: true
end
