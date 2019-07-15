# frozen_string_literal: true

module Payments
  class Payout < Operation
    include Methods

    PAYMENT_METHODS = [
      ::Payments::Methods::CREDIT_CARD,
      ::Payments::Methods::NETELLER,
      ::Payments::Methods::SKRILL,
      ::Payments::Methods::BITCOIN
    ].freeze

    def execute_operation
      provider.process_payout(transaction)
    end
  end
end
