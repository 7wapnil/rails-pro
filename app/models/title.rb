class Title < ApplicationRecord
  include HasUniqueExternalId

  has_many :events, dependent: :destroy
  has_many :event_scopes, dependent: :destroy
  has_many :tournaments, -> { where kind: :tournament },
           class_name: 'EventScope'

  enum kind: {
    esports: 0,
    sports: 1
  }

  validates :name, :kind, presence: true
  validates :name, uniqueness: true
end
