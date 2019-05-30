module Payments
  module Wirecard
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        response = request_payment_session(transaction)
        response['payment-redirect-url']
      end

      def payment_response_handler
        ::Payments::Wirecard::PaymentResponse
      end

      def client
        @client ||= Client.new
      end

      private

      def request_payment_session(transaction)
        response = client.authorize_payment(transaction)
        response.parsed_response
      rescue ::HTTParty::ResponseError => error
        Rails.logger.error(error)
        raise ::Payments::GatewayError, 'Technical gateway error'
      end
    end
  end
end
