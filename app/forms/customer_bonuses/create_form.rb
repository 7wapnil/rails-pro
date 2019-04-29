# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_accessor :subject

    validate :ensure_no_active_bonus
    validate :validate_repeated_activation

    delegate :customer, :original_bonus, to: :subject

    def submit!
      validate!
      subject.save!
    end

    private

    def validate!
      return if valid?

      error_message = errors.full_messages.join("\n")
      raise CustomerBonuses::ActivationError, error_message
    end

    def ensure_no_active_bonus
      return unless find_existing_bonus

      raise CustomerBonuses::ActivationError,
            I18n.t('errors.messages.customer_has_active_bonus')
    end

    def validate_repeated_activation
      return if original_bonus.repeatable

      duplicate = CustomerBonus.find_by(customer: customer,
                                        original_bonus: original_bonus)
      return unless duplicate

      raise CustomerBonuses::ActivationError,
            I18n.t('errors.messages.repeated_bonus_activation')
    end

    def find_existing_bonus
      Customer.find_by(id: customer.id)&.active_bonus
    end
  end
end
