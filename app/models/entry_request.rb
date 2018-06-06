class EntryRequest < ApplicationRecord
  include EntryKinds

  enum status: {
    pending: 0,
    success: 1,
    fail: 2
  }

  validates :status, inclusion: { in: statuses.keys }
  validates :payload, presence: true
  validates :payload, entry_request_payload: true

  def payload
    return unless self[:payload]

    EntryRequestPayload.new(self[:payload].symbolize_keys)
  end
end
