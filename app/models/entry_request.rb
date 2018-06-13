class EntryRequest < ApplicationRecord
  include EntryKinds

  belongs_to :customer
  belongs_to :currency

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

  enum origin_type: ORIGINS

  validates :amount,
            :kind,
            :origin_type,
            :origin_id,
            :comment,
            presence: true
  validates :amount, numericality: true
  validates :status, inclusion: { in: statuses.keys }
  validates :kind, inclusion: { in: kinds.keys }
  validates :origin_type, inclusion: { in: origin_types.keys }

  def origin
    origin_type
      .to_s
      .camelize
      .safe_constantize
      &.find(origin_id)
  end

  def result_message
    return unless self[:result]

    @message = self[:result]['message']
  end
end
