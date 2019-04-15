module Forms
  class WithdrawRequest
    include ActiveModel::Model

    PAYMENT_METHOD_MODELS = {
      EntryRequest::CREDIT_CARD => Forms::PaymentMethods::CreditCard
    }.freeze

    attr_accessor :amount,
                  :password,
                  :wallet_id,
                  :payment_method,
                  :payment_details,
                  :customer

    validates :password,
              :amount,
              :wallet_id,
              :payment_method, presence: true
    validates :amount,
              numericality: { greater_than: 0 },
              format: { with: /\A\d{1,12}(\.\d{0,2})?\z/ }
    validates :payment_method,
              inclusion: {
                in: SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.keys,
                message: I18n.t(
                  'errors.messages.withdrawal.method_not_supported'
                )
              }
    validate :validate_customer_status
    validate :validate_payment_details

    def validate_payment_details
      return unless PAYMENT_METHOD_MODELS.key?(payment_method)

      method_model = PAYMENT_METHOD_MODELS[payment_method].new(
        payment_details_map
      )
      return if method_model.valid?

      method_model.errors.each do |attr, error|
        errors.add(attr, error)
      end
    end

    def validate_customer_status
      valid = customer.verified
      errors.add(:customer, I18n.t(
        'errors.messages.withdrawal.customer_not_verified'
      ))
    end

    def payment_details_map
      Array.wrap(payment_details).reduce({}) do |result, item|
        result.merge(item[:code] => item[:value])
      end
    end
  end
end
