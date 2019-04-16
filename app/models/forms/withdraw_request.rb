module Forms
  class WithdrawRequest
    include ActiveModel::Model

    PAYMENT_METHOD_MODELS = {
      EntryRequest::CREDIT_CARD => Forms::PaymentMethods::CreditCard
    }.freeze

    MIN_AMOUNT = 0
    MAX_AMOUNT = 10_000

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
              numericality: {
                greater_than: MIN_AMOUNT, less_than: MAX_AMOUNT
              },
              format: { with: /\A\d{1,12}(\.\d{0,2})?\z/ }
    validates :payment_method,
              inclusion: {
                in: SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.keys,
                message: I18n.t(
                  'errors.messages.withdrawal.method_not_supported'
                )
              }
    validate :validate_customer_status
    validate :validate_customer_password
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
      return if customer.nil? || customer.verified

      raise ResolvingError,
            customer: I18n.t('errors.messages.withdrawal.customer_not_verified')
    end

    def payment_details_map
      Array.wrap(payment_details).reduce({}) do |result, item|
        result.merge(item[:code] => item[:value])
      end
    end

    def validate_customer_password
      return if customer.nil? || customer.valid_password?(password)

      raise ResolvingError,
            password: I18n.t('errors.messages.password_invalid')
    end
  end
end
