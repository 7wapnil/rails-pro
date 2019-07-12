# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_reader :subject

    validate :ensure_no_active_bonus
    validate :validate_repeated_activation

    delegate :customer, :original_bonus, to: :subject

    def initialize(bonus_attributes)
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
  end
end
