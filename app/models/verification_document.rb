# frozen_string_literal: true

class VerificationDocument < ApplicationRecord
  include Loggable

  acts_as_paranoid

  MAX_ATTACHMENT_SIZE = 2.megabytes.freeze
  ALLOWED_FORMATS = %w[image/jpeg
                       image/png
                       image/jpg
                       application/pdf].freeze
  KINDS = {
    personal_id:    PERSONAL_ID    = 'personal_id',
    utility_bill:   UTILITY_BILL   = 'utility_bill',
    bank_statement: BANK_STATEMENT = 'bank_statement',
    credit_card:    CREDIT_CARD    = 'credit_card',
    other_document: OTHER_DOCUMENT = 'other_document'
  }.freeze

  enum kind: KINDS

  enum status: {
    pending:   PENDING   = 'pending',
    confirmed: CONFIRMED = 'confirmed',
    rejected:  REJECTED  = 'rejected'
  }

  belongs_to :customer
  has_one_attached :document
  has_many :comments, as: :commentable

  validates :document, presence: true
  validates :document,
            file_size: { less_than_or_equal_to: MAX_ATTACHMENT_SIZE },
            file_content_type: { allow: ALLOWED_FORMATS }

  scope :recently_actioned, -> { where(status: %i[confirmed rejected]) }
  delegate :filename, to: :document

  def loggable_attributes
    { id: id,
      kind: kind,
      status: status }
  end
end
