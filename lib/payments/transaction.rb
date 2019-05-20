module Payments
  class Transaction
    include ::ActiveModel::Model
    include Methods
    attr_accessor :customer, :amount, :currency, :bonus_code

    validates :customer, :amount, :currency, presence: true

    def self.build(method)
      support = TRANSACTIONS[method].present?
      err_msg = "#{method} is not supported"
      raise ::Payments::Errors::NotSupportedError, err_msg unless support

      TRANSACTIONS[method].new
    end

    def deposit_provider
      raise ::NotImplementedError
    end
  end
end
