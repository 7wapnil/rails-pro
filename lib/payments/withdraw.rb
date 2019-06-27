# frozen_string_literal: true

module Payments
  class Withdraw < Operation
    include Methods

    PAYMENT_METHODS = [
      ::Payments::Methods::CREDIT_CARD,
      ::Payments::Methods::NETELLER,
      ::Payments::Methods::SKRILL,
      ::Payments::Methods::BITCOIN
    ].freeze

    def execute_operation
      provider.process_withdrawal(transaction)
    end
  end
end
