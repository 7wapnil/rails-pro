module Payments
  module SafeCharge
    class PaymentResponse < ::Payments::PaymentResponse
      def status
        STATUS_CANCELED
      end

      def request_id
        ::EntryRequest.last.id
      end
    end
  end
end
