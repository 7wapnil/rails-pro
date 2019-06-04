# frozen_string_literal: true

module Payments
  module SafeCharge
    class PaymentResponse < ::Payments::PaymentResponse
      # TODO: implement Coinspaid functionality
      def status
        'status'
      end

      def request_id
        'id'
      end
    end
  end
end
