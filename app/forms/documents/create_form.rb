# frozen_string_literal: true

module Documents
  class CreateForm
    include ActiveModel::Model

    MAX_ATTACHMENT_SIZE = 2.megabytes

    attr_accessor :document

    validate :document_size

    private

    def document_size
      return if document.size < MAX_ATTACHMENT_SIZE

      errors.add(:file_size, I18n.t('errors.messages.document_size_limit'))
    end
  end
end
