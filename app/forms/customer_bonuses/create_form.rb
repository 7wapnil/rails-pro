# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_reader :subject, :amount, :currency

    validate :ensure_no_active_bonus
    validate :validate_repeated_activation
    validate :minimal_bonus_amount

    delegate :customer, :original_bonus, to: :subject

    def initialize(amount:, currency: nil, **bonus_attributes)
      @amount = amount
      @currency = currency || Currency.primary
      @subject = CustomerBonus.new(bonus_attributes)
    end

    def submit!
      validate!
      subject.save!
    end

    def validate!
      return if valid?

      raise CustomerBonuses::ActivationError, displayed_error
    end

    private

    def minimal_bonus_amount
      return if amount.present? && amount >= min_deposit

      errors.add(:bonus,
                 I18n.t('errors.messages.bonus_minimum_requirements_failed'))
    end

    def ensure_no_active_bonus
      return unless customer&.active_bonus

      errors.add(:active_bonus,
                 I18n.t('errors.messages.customer_has_active_bonus'))
    end

    def validate_repeated_activation
      return if original_bonus.repeatable

      duplicate = CustomerBonus.find_by(customer: customer,
                                        original_bonus: original_bonus,
                                        status: CustomerBonus::USED_STATUSES)
      return unless duplicate

      errors.add(:bonus,
                 I18n.t('errors.messages.repeated_bonus_activation'))
    end

    def displayed_error
      # [1] takes the error message itself instead of key-value pair
      errors.first[1]
    end

    def min_deposit
      @min_deposit ||= Exchanger::Converter.call(
        original_bonus.min_deposit,
        Currency.primary,
        currency
      )
    end
  end
end
