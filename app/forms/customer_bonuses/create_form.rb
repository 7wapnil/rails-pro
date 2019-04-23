module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    attr_accessor :subject

    delegate :customer, to: :subject

    def validate!
      ensure_no_active_bonus
    end

    private

    def ensure_no_active_bonus
      existing_bonus = Customer.find(customer.id).active_bonus
      valid = existing_bonus.nil?
      message_key = 'errors.messages.customer_has_active_bonus'
      raise CustomerBonuses::ActivationError, I18n.t(message_key) unless valid
    end
  end
end
