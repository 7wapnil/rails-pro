class Event < ApplicationRecord
  include Visible

  after_create :emit_created
  after_update :emit_updated

  UPDATABLE_ATTRIBUTES = %w[name description start_at end_at].freeze

  PRIORITIES = [0, 1, 2].freeze

  STATUSES = {
    not_started: 0,
    started: 1,
    ended: 2,
    closed: 3
  }.freeze

  belongs_to :title
  has_many :markets
  has_many :bets, through: :markets
  has_many :scoped_events
  has_many :event_scopes, through: :scoped_events

  validates :name, presence: true
  validates :priority, inclusion: { in: PRIORITIES }

  enum status: STATUSES

  delegate :name, to: :title, prefix: true

  def self.in_play
    where(
      'start_at < ? AND end_at IS NULL AND traded_live IS TRUE',
      Time.zone.now
    )
  end

  def self.today
    where(start_at: [Date.today.beginning_of_day..Date.today.end_of_day])
  end

  def in_play?
    traded_live && start_at.past? && end_at.nil?
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

  def wager
    bets.sum(:amount)
  end

  def tournament
    event_scopes.where(kind: :tournament).first
  end

  private

  def emit_created
    WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_CREATED,
                                    id: id.to_s)
  end

  def emit_updated
    excluded_keys = %w[updated_at payload]
    changes = previous_changes
              .except(*excluded_keys)
              .transform_values! { |v| v[1] }
    return if changes.empty?

    WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_UPDATED,
                                    id: id.to_s,
                                    changes: changes)
  end
end
