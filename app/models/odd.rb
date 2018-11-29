class Odd < ApplicationRecord
  enum status: {
    inactive: 0,
    active: 1
  }

  belongs_to :market
  has_many :bets

  validates :name, :status, presence: true
  validates :value, presence: true,
                    on: :create,
                    if: proc { |odd| odd.active? }
  validates :value, numericality: { greater_than: 0 }, allow_nil: true

  after_create :emit_created
  after_update :emit_updated

  private

  def emit_created
    WebSocket::Client.instance.emit(WebSocket::Signals::ODD_CREATED,
                                    id: id.to_s,
                                    marketId: market.id.to_s,
                                    eventId: market.event_id.to_s)
  end

  def emit_updated
    changes = {}
    previous_changes.each do |attr, changed|
      changes[attr.to_sym] = changed[1] unless attr == 'updated_at'
    end
    return if changes.empty?

    WebSocket::Client.instance.emit(WebSocket::Signals::ODD_UPDATED,
                                    id: id.to_s,
                                    marketId: market.id.to_s,
                                    eventId: market.event_id.to_s,
                                    changes: changes)
  end
end
