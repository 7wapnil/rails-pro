# frozen_string_literal: true

module Forms
  class AmountChange
    include ActiveModel::Model

    attr_accessor :subject, :amount, :request

    validates :amount,
              numericality: {
                greater_than_or_equal_to: 0,
                message: I18n.t('errors.messages.not_negative')
              }

    def initialize(subject, amount:, request:)
      @subject = subject
      @amount = amount
      @request = request
    end

    def save!
      validate!
      subject.with_lock { subject.update(amount: amount) }
    end

    private

    def requested_by_user?
      EntryKinds::SYSTEM_KINDS.exclude?(request.kind.to_s)
    end
  end
end
