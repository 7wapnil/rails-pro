# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_accessor :subject

    delegate :customer, to: :subject

    def submit!
      validate!
      subject.save!
    end

    private

    def validate!
      ensure_no_active_bonus
    end

    def ensure_no_active_bonus
      return true unless find_existing_bonus

      raise CustomerBonuses::ActivationError,
            I18n.t('errors.messages.customer_has_active_bonus')
    end

    def find_existing_bonus
      Customer.find_by(id: customer.id)&.active_bonus
    end
  end
end
