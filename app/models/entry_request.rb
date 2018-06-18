class EntryRequest < ApplicationRecord
  include EntryKinds

  belongs_to :customer
  belongs_to :currency
  belongs_to :origin, polymorphic: true

  default_scope { order(created_at: :desc) }

  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2
  }

  validates :amount,
            :kind,
            :comment,
            presence: true

  validates :amount, numericality: true
  validates :status, inclusion: { in: statuses.keys }
  validates :kind, inclusion: { in: kinds.keys }

  def result_message
    return unless self[:result]

    @message = self[:result]['message']
  end
end
