class EntryRequest < ApplicationRecord
  include EntryKinds

  belongs_to :customer
  belongs_to :currency
  belongs_to :initiator, polymorphic: true

  default_scope { order(created_at: :desc) }

  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2
  }

  validates :amount,
            :kind,
            presence: true

  validates :comment, presence: true, unless: :customer_initiated?
  validates :amount, numericality: true
  validates :status, inclusion: { in: statuses.keys }
  validates :kind, inclusion: { in: kinds.keys }

  def customer_initiated?
    self[:initiator_type] == Customer.to_s
  end

  def result_message
    return unless self[:result]

    @message = self[:result]['message']
  end
end
