# frozen_string_literal: true

module Payments
  module SafeCharge
    class DepositResponse < ::Payments::DepositCallbackHandler
      include ::Payments::SafeCharge::Statuses

      def initialize(response)
        @response = response
      end

      def call
        return cancel_entry_request if cancelled?
        return if failed_attempt?

        save_transaction_id! unless entry_request.external_id
        update_entry_request_mode!

        return if pending?
        return complete_entry_request! if approved?

        fail_entry_request!
      end

      private

      def cancelled?
        status == ::Payments::Webhooks::Statuses::CANCELLED
      end

      def status
        response[:Status]
      end

      def cancel_entry_request
        Rails.logger.warn(message: 'Payment request canceled',
                          status: status,
                          payment_message_status: payment_message_status,
                          request_id: request_id)
        entry_request.register_failure!(
          I18n.t('errors.messages.cancelled_by_customer')
        )
        fail_bonus
      end

      def payment_message_status
        response[:ppp_status]
      end

      def request_id
        response[:request_id]
      end

      def failed_attempt?
        payment_message_status == FAIL && status == DECLINED
      end

      def save_transaction_id!
        entry_request.update!(external_id: transaction_id)
      end

      def transaction_id
        response[:PPP_TransactionID]
      end

      def update_entry_request_mode!
        ::Payments::SafeCharge::PaymentMethodService.call(
          payment_method_code: response[:payment_method],
          entry_request:       entry_request
        )
      end

      def pending?
        status == PENDING && payment_message_status == PENDING
      end

      def fail_entry_request!
        Rails.logger.warn(message: 'Payment request failed',
                          status: status,
                          payment_message_status: payment_message_status,
                          reason: response[:Reason],
                          reason_code: response[:ReasonCode],
                          request_id: request_id)
        entry_request.register_failure!(
          I18n.t('errors.messages.payment_failed_with_reason_error',
                 reason: response[:Reason])
        )
        fail_bonus

        raise ::Payments::TechnicalError
      end

      def approved?
        status == APPROVED && payment_message_status == OK
      end

      def complete_entry_request!
        return if entry_request.succeeded?

        ::EntryRequests::DepositService.call(entry_request: entry_request)
      end

      def throw_unknown_status
        raise ::Payments::NotSupportedError, "Unknown response status #{status}"
      end
    end
  end
end
