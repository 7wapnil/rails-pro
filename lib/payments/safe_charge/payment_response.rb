module Payments
  module SafeCharge
    class PaymentResponse < ::Payments::PaymentResponse
      def status
        @response[:result].to_sym
      end

      def request_id
        @response[:request_id]
      end
    end
  end
end
