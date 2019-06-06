# frozen_string_literal: true

module Payments
  class PaymentResponse < ::ApplicationService
    STATUS_SUCCESS = :success
    STATUS_FAILED = :failed
    STATUS_PENDING = :pending
    STATUS_CANCELED = :cancelled
    NOTIFICATION = :notification

    def initialize(response)
      @response = response
    end

    def call
      return if status == STATUS_PENDING

      return handle_notification if status == NOTIFICATION
      return cancel_entry_request! if status == STATUS_CANCELED
      return fail_entry_request! if status == STATUS_FAILED
      return complete_entry_request! if status == STATUS_SUCCESS

      throw_unknown_status
    end

    def entry_request
      @entry_request ||= ::EntryRequest.find(request_id)
    end

    def status
      raise ::NotImplementedError
    end

    def request_id
      raise ::NotImplementedError
    end

    def status_message; end

    private

    def handle_notification; end

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
