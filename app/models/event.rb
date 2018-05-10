class Event < ApplicationRecord
  default_scope do
    where('start_at > ?', Date.yesterday.end_of_day).order(:start_at)
  end

  belongs_to :discipline
  has_many :markets
  has_many :scoped_events
  has_many :event_scopes, through: :scoped_events

  validates :name, presence: true

  def self.in_play
    where('start_at < ? AND end_at IS NULL', Time.zone.now)
  end

  def self.today
    where(start_at: [Date.today.beginning_of_day..Date.today.end_of_day])
  end

  def in_play?
    start_at.past? && end_at.nil?
  end
end
