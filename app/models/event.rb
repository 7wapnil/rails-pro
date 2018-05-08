class Event < ApplicationRecord
  belongs_to :discipline
  has_many :markets

  has_many :scoped_events
  has_many :event_scopes, through: :scoped_events

  validates :name, presence: true
end
