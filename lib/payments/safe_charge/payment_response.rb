module Payments
  module SafeCharge
    class PaymentResponse < ::Payments::PaymentResponse
      def status
        return parse_state if result_state == :notification

        result_state
      end

      def request_id
        @response[:request_id]
      end

      private

      def result_state
        @response[:result].to_sym
      end

      def parse_state
      end
    end
  end
end
