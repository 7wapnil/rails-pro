# frozen_string_literal: true

module Forms
  class AmountChange
    include ActiveModel::Model

    attr_accessor :subject, :request, :amount_increment,
                  :real_money_amount_increment, :bonus_amount_increment

    validates :amount_increment, numericality: true
    validates :real_money_amount_increment, numericality: true
    validates :bonus_amount_increment, numericality: true
    validate :real_money_amount_not_negative, if: :new_outgoing_activity?
    validate :bonus_amount_not_negative, if: :new_outgoing_activity?

    def initialize(subject, request:)
      @subject = subject
      @real_money_amount_increment = request.real_money_amount
      @bonus_amount_increment = request.bonus_amount
      @amount_increment = request.real_money_amount + request.bonus_amount
      @request = request
    end

    def save!
      validate!
      subject.update!(
        amount: subject.amount + amount_increment,
        real_money_balance: subject.real_money_balance +
                            real_money_amount_increment,
        bonus_balance: subject.bonus_balance + bonus_amount_increment
      )
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

    def real_money_amount_not_negative
      result_amount = subject.real_money_balance +
                      real_money_amount_increment.to_d
      message = I18n.t('errors.messages.amount_not_negative',
                       subject: subject.to_s,
                       current_amount: subject.real_money_balance,
                       new_amount: result_amount)

      errors.add(:base, message) if result_amount.negative?
    end

    def bonus_amount_not_negative
      result_amount = subject.bonus_balance + bonus_amount_increment.to_d
      message = I18n.t('errors.messages.amount_not_negative',
                       subject: subject.to_s,
                       current_amount: subject.bonus_balance,
                       new_amount: result_amount)

      errors.add(:base, message) if result_amount.negative?
    end
  end
end
