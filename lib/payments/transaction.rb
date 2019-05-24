module Payments
  class Transaction
    include ::ActiveModel::Model

    MIN_AMOUNT = 0
    MAX_AMOUNT = 10_000

    attr_accessor :id, :method, :customer, :amount, :currency, :bonus_code

    validates :method, :customer, :amount, :currency, presence: true
    validates :amount,
              numericality: {
                greater_than: MIN_AMOUNT, less_than: MAX_AMOUNT
              },
              format: { with: /\A\d{1,12}(\.\d{0,2})?\z/ }

    def wallet
      @wallet ||= Wallet.find_or_create_by!(customer: customer,
                                            currency: currency)
    end

    def bonus
      @bonus ||= Bonus.find_by_code(bonus_code)
    end
  end
end
