# frozen_string_literal: true

module Payments
  module Fiat
    class Payout < Operation
      include Methods

      PAYMENT_METHODS = [
        ::Payments::Methods::CREDIT_CARD,
        ::Payments::Methods::NETELLER,
        ::Payments::Methods::SKRILL,
        ::Payments::Methods::IDEBIT
      ].freeze

      def execute_operation
        provider.process_payout
      end
    end
  end
end
