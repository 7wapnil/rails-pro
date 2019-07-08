# frozen_string_literal: true

module Payments
  module Wirecard
    class DepositResponse < ::Payments::DepositCallbackHandler
      include ::Payments::Wirecard::Statuses
      include ::Payments::Wirecard::TransactionStates

      def initialize(params)
        @response = JSON.parse(Base64.decode64(params['response-base64']))
      end

      def call
        return cancel_entry_request if cancelled?

        save_transaction_id! unless entry_request.external_id

        return complete_entry_request if approved?

        fail_entry_request
      end

      private

      def cancelled?
        CANCELLED_STATUSES.include?(status_details['code']) &&
          transaction_state == FAILED
      end

      def status_details
        @status_details ||=
          response.dig('payment', 'statuses', 'status').to_a.last.to_h
      end

      def transaction_state
        @transaction_state ||= response.dig('payment', 'transaction-state')
      end

      def cancel_entry_request
        Rails.logger.warn message: 'Payment request cancelled',
                          status: status_details['code'],
                          status_message: status_details['description'],
                          request_id: request_id
        entry_request.register_failure!(
          I18n.t('errors.messages.cancelled_by_customer')
        )
        fail_bonus

        raise ::Payments::CancelledError
      end

      def request_id
        @request_id ||=
          response.dig('payment', 'request-id').to_s.split(':').last.to_i
      end

      def save_transaction_id!
        entry_request.update!(external_id: transaction_id)
      end

      def transaction_id
        response.dig('payment', 'transaction-id')
      end

      def approved?
        status_details['code'].match?(APPROVED_STATUSES_REGEX) &&
          transaction_state == SUCCESSFUL
      end

      def complete_entry_request
        ::EntryRequests::DepositWorker.perform_async(entry_request.id)
      end

      def fail_entry_request
        Rails.logger.warn message: 'Payment request failed',
                          status: status_details['code'],
                          status_message: status_details['description'],
                          request_id: request_id
        entry_request.register_failure!(
          I18n.t('errors.messages.payment_failed_with_reason_error',
                 reason: status_details['description'])
        )
        fail_bonus

        raise ::Payments::FailedError
      end
    end
  end
end
