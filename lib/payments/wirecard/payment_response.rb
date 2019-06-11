# frozen_string_literal: true

module Payments
  module Wirecard
    class PaymentResponse < ::Payments::PaymentResponse
      def call
        return if [STATUS_NOTIFICATION, STATUS_PENDING].include?(status)

        return cancel_entry_request! if status == STATUS_CANCELLED
        return fail_entry_request! if status == STATUS_FAILED
        return complete_entry_request! if status == STATUS_SUCCESS

        throw_unknown_status
      end

      private

      def status
        parsed_response.dig('payment', 'transaction-state').to_sym
      end

      def parsed_response
        @parsed_response ||= JSON.parse(
          Base64.decode64(@response['response-base64'])
        )
      end

      def cancel_entry_request!
        Rails.logger.warn message: 'Payment request canceled',
                          status: status,
                          status_message: status_message,
                          request_id: request_id
        entry_request.register_failure!(
          I18n.t('errors.messages.cancelled_by_customer')
        )

        raise ::Payments::CancelledError
      end

      def entry_request
        @entry_request ||= ::EntryRequest.find(request_id)
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

      def fail_entry_request!
        Rails.logger.warn message: 'Payment request failed',
                          status: status,
                          status_message: status_message,
                          request_id: request_id
        entry_request.register_failure!(
          I18n.t('errors.messages.payment_failed_error')
        )

        raise ::Payments::TechnicalError
      end

      def complete_entry_request!
        ::EntryRequests::DepositService.call(entry_request: entry_request)
      end

      def throw_unknown_status
        raise ::Payments::NotSupportedError, "Unknown response status #{status}"
      end
    end
  end
end
