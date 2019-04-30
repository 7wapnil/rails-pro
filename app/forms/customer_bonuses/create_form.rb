# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_accessor :subject

    delegate :customer, :original_bonus, to: :subject
    delegate :active_bonus, to: :reloaded_customer, allow_nil: true

    def submit!
      validate!
      subject.save!
    end

    private

    def validate!
      ensure_no_active_bonus && validate_repeated_activation
    end

    def ensure_no_active_bonus
      return true unless active_bonus

      raise CustomerBonuses::ActivationError,
            I18n.t('errors.messages.customer_has_active_bonus')
    end

    def validate_repeated_activation
      duplicate = CustomerBonus.find_by(customer: customer,
                                        original_bonus: original_bonus)
      return true unless duplicate
      return true if original_bonus.repeatable

      raise CustomerBonuses::ActivationError,
            I18n.t('errors.messages.repeated_bonus_activation')
    end

    def reloaded_customer
      customer&.reload
    end
  end
end
