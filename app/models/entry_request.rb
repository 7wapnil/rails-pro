class EntryRequest < ApplicationRecord
  include EntryKinds

  ORIGINS = {
    user: 0,
    customer: 1
  }.freeze

  default_scope { order(created_at: :desc) }

  enum status: {
    pending: 0,
    success: 1,
    fail: 2
  }

  validates :status, inclusion: { in: statuses.keys }
  validates :payload, presence: true

  def payload
    return unless self[:payload]

    EntryRequestPayload.new(self[:payload].symbolize_keys)
  end

  def result_message
    return unless self[:result]

    @message = self[:result]['message']
  end
end
