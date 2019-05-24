module Payments
  module SafeCharge
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        PaymentPageUrl.call(transaction)
      end

      def client
        @client ||= Client.new
      end
    end
  end
end
