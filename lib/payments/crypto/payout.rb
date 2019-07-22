# frozen_string_literal: true

module Payments
  module Crypto
    class Payout < Operation
      include Methods

      PAYMENT_METHODS = [
        ::Payments::Methods::BITCOIN
      ].freeze

      def execute_operation
        provider.process_payout
      end
    end
  end
end
