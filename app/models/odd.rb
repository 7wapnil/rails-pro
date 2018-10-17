class Odd < ApplicationRecord
  after_create :emit_created
  after_update :emit_updated

  enum status: {
    inactive: 0,
    active: 1
  }

  belongs_to :market

  validates :name, :value, :status, presence: true
  validates :value, numericality: { greater_than: 0 }

  def settle
    return :unsettled if won.nil?
    won ? :won : :lost
  end

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
