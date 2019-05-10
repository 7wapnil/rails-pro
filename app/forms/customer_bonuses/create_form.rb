# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_accessor :subject

    validate :ensure_no_active_bonus
    validate :validate_repeated_activation

    delegate :customer, :original_bonus, to: :subject
    delegate :active_bonus, to: :'customer&.reload', allow_nil: true

    def submit!
      validate!
      subject.save!
    end

    private

    def validate!
      return if valid?

      raise CustomerBonuses::ActivationError, displayed_error
    end

    def ensure_no_active_bonus
      return unless active_bonus

      errors.add(:active_bonus,
                 I18n.t('errors.messages.customer_has_active_bonus'))
    end

    def validate_repeated_activation
      return if original_bonus.repeatable

      duplicate = CustomerBonus.find_by(customer: customer,
                                        original_bonus: original_bonus)
      return unless duplicate

      errors.add(:bonus,
                 I18n.t('errors.messages.repeated_bonus_activation'))
    end

    def displayed_error
      # [1] takes the error message itself instead of key-value pair
      errors.first[1]
    end
  end
end
