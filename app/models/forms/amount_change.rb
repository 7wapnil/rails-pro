# frozen_string_literal: true

module Forms
  class AmountChange
    include ActiveModel::Model

    attr_accessor :subject, :amount_increment, :request

    validates :amount_increment, numericality: true
    # TODO: remove the line below after merge develop
    validate :amount_not_negative, if: :new_outgoing_activity?
    # TODO: uncomment the block below after merge develop
    # validates :real_money_amount_increment, numericality: true
    # validates :bonus_amount_increment, numericality: true
    # validate :real_money_amount_not_negative, if: :new_outgoing_activity?
    # validate :bonus_amount_not_negative, if: :new_outgoing_activity?

    def initialize(subject, amount_increment:, request:)
      @subject = subject
      @amount_increment = amount_increment
      @request = request
    end

    def save!
      subject.with_lock do
        validate!
        subject.update!(amount: subject.amount + amount_increment)
      end
    end

    private

    def new_outgoing_activity?
      EntryKinds::ALLOWED_NEGATIVE_BALANCE_KINDS.exclude?(request.kind.to_s)
    end

    def amount_not_negative
      result_amount = subject.amount + amount_increment.to_d
      message = I18n.t('errors.messages.amount_not_negative',
                       subject: subject.to_s,
                       current_amount: subject.amount,
                       new_amount: result_amount)

      errors.add(:base, message) if result_amount.negative?
    end
  end
end
