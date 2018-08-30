class Event < ApplicationRecord
  UPDATABLE_ATTRIBUTES = %w[name description start_at end_at].freeze

  belongs_to :title
  has_many :markets
  has_many :scoped_events
  has_many :event_scopes, through: :scoped_events

  validates :name, presence: true

  delegate :name, to: :title, prefix: true

  def self.in_play
    where('start_at < ? AND end_at IS NULL', Time.zone.now)
  end

  def self.today
    where(start_at: [Date.today.beginning_of_day..Date.today.end_of_day])
  end

  def in_play?
    start_at.past? && end_at.nil?
  end

  def update_from!(other)
    unless other.is_a?(self.class)
      raise TypeError, 'Passed \'other\' argument is not an Event'
    end

    assign_attributes(other.attributes.slice(*UPDATABLE_ATTRIBUTES))

    payload.merge!(other.payload) if payload && other.payload
    self.payload = other.payload unless payload

    save!
    self
  end
end
