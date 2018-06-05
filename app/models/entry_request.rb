class EntryRequest < ApplicationRecord
  include EntryKinds

  ENTRY_PAYLOAD_SCHEMA = Rails.root.join('config',
                                         'schemas',
                                         'entry_payload.json').to_s

  enum status: {
    pending: 0,
    success: 1,
    fail: 2
  }

  validates :status, inclusion: { in: statuses.keys }
  validates :payload, presence: true, json: { schema: ENTRY_PAYLOAD_SCHEMA }
end
