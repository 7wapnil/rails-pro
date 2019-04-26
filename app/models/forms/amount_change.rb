# frozen_string_literal: true

module Forms
  class AmountChange
    include ActiveModel::Model

    attr_accessor :subject, :amount_increment, :request

    validates :amount_increment, numericality: true
    validate :amount_not_negative, if: :requested_by_user?

    def initialize(subject, amount_increment:, request:)
      @subject = subject
      @amount_increment = amount_increment
      @request = request
    end

    def save!
      subject.with_lock do
        validate!
        subject.increment!(:amount, amount_increment)
      end
    end

    private

    def requested_by_user?
      EntryKinds::SYSTEM_KINDS.exclude?(request.kind.to_s)
    end

    def amount_not_negative
      result_amount = subject.amount + amount_increment.to_d
      message = I18n.t('errors.messages.not_negative')
      errors.add(:base, message) if result_amount.negative?
    end
  end
end
