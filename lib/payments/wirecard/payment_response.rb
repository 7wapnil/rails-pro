module Payments
  module Wirecard
    class PaymentResponse < ::Payments::PaymentResponse
      def status
        parsed_response.dig('payment', 'transaction-state').to_sym
      end

      def request_id
        request_data = parsed_response.dig('payment', 'request-id')
        request_data.split(':')[1].to_i
      end

      def status_message
        status = parsed_response.dig('payment', 'statuses', 'status')
        return nil unless status.present?

        status[0]['description']
      end

      private

      def parsed_response
        @parsed_response ||= JSON.parse(
          Base64.decode64(@response['response-base64'])
        )
      end
    end
  end
end
