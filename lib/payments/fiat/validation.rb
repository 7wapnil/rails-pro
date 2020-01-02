# frozen_string_literal: true

module Payments
  module Fiat
    class Validation < Operation
      include Methods

      def execute_operation
        provider.validate_customer
      end
    end
  end
end
