class VerificationDocument < ApplicationRecord
  MAX_ATTACHMENT_SIZE = 2.megabytes.freeze
  KINDS = {
    personal_id: 0,
    utility_bill: 1,
    bank_statement: 2,
    credit_card: 3,
    other_document: 4
  }.freeze

  enum kind: KINDS

  enum status: {
    absent: 0,
    pending: 1,
    confirmed: 2,
    rejected: 3
  }

  belongs_to :customer
  has_one_attached :document

  validates :document, presence: true
  validates :document,
            file_size: { less_than_or_equal_to: MAX_ATTACHMENT_SIZE },
            file_content_type: { allow: %w[image/jpeg
                                           image/png
                                           image/jpg
                                           application/pdf] }

  delegate :filename, to: :document
end
