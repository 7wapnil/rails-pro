module Payments
  class Transaction
    include ::ActiveModel::Model

    MIN_AMOUNT = 0
    MAX_AMOUNT = 10_000
    MAX_DEPOSIT_ATTEMPTS = ENV.fetch('MAX_DEPOSIT_ATTEMPTS', 5).to_i

    attr_accessor :id, :method, :customer, :amount, :currency, :bonus_code

    validates :method, :customer, :amount, :currency, presence: true
    validates :amount,
              numericality: {
                greater_than: MIN_AMOUNT, less_than: MAX_AMOUNT
              },
              format: { with: /\A\d{1,12}(\.\d{0,2})?\z/ }

    validate :deposit_attempts
    validates_with DepositLimitValidator

    def deposit_attempts
      return unless customer

      return unless customer.deposit_attempts <= MAX_DEPOSIT_ATTEMPTS

      errors.add(:amount, I18n.t('errors.messages.deposit_attempts_exceeded'))
    end

    def wallet
      @wallet ||= Wallet.find_or_create_by!(customer: customer,
                                            currency: currency)
    end

    def bonus
      @bonus ||= Bonus.find_by_code(bonus_code)
    end
  end
end
