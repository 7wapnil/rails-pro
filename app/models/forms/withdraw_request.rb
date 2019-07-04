# frozen_string_literal: true

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
                  :details,
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
    validate :validate_details
    validate :validate_no_pending_bets_with_bonus

    def validate_details
      return unless PAYMENT_METHOD_MODELS.key?(payment_method)

      method_model = PAYMENT_METHOD_MODELS[payment_method].new(
        details_map
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

    def details_map
      Array.wrap(details).reduce({}) do |result, item|
        result.merge(item[:code] => item[:value])
      end
    end

    def validate_customer_password
      return if customer.nil? || customer.valid_password?(password)

      raise ResolvingError,
            password: I18n.t('errors.messages.password_invalid')
    end

    def validate_no_pending_bets_with_bonus
      return if !customer || no_pending_bets_with_bonus?

      errors.add(:base,
                 I18n.t('errors.messages.withdrawal.pending_bets_with_bonus'))
    end

    def no_pending_bets_with_bonus?
      customer
        .bets
        .pending
        .joins(entry_requests: :bonus_balance_entry_request)
        .none?
    end
  end
end
