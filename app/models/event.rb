class Event < ApplicationRecord
  after_create :emit_created
  after_update :emit_updated

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
    payload&.merge!(addition)
    self.payload = addition unless payload
  end

  private

  def emit_created
    WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_CREATED,
                                    id: id.to_s)
  end

  def emit_updated
    changes = {}
    previous_changes.each do |attr, changed|
      changes[attr.to_sym] = changed[1] unless attr == 'updated_at'
    end
    WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_UPDATED,
                                    id: id.to_s,
                                    changes: changes)
  end
end
