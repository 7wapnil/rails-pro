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
    add_to_payload(other.payload)

    save!
    self
  end

  # This is a good candidate to be extracted to a reusable concern
  def add_to_payload(addition)
    return unless addition
    payload.merge!(addition) if payload
    self.payload = addition unless payload
  end
end
