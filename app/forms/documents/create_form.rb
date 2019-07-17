# frozen_string_literal: true

module Documents
  class CreateForm
    include ActiveModel::Model

    MAX_ATTACHMENT_SIZE = 10.megabytes.freeze
    ALLOWED_FORMATS = %w[image/jpeg
                         image/png
                         image/jpg
                         application/pdf].freeze

    attr_accessor :document

    validates :document, presence: true
    validates :document,
              file_size: { less_than_or_equal_to: MAX_ATTACHMENT_SIZE },
              file_content_type: { allow: ALLOWED_FORMATS }
  end
end
