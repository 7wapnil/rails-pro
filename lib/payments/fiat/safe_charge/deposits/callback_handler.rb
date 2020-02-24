# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        class CallbackHandler < Handlers::DepositCallbackHandler
          include ::Payments::Fiat::SafeCharge::Statuses

          def call
            return cancel_entry_request if cancelled?
            return if failed_attempt?

            save_transaction_id! unless entry_request.external_id
            update_entry_request_mode!
            update_deposit_details!

            return if pending?
            return track_and_complete! if approved?

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

            ga_client.track_deposit_cancellation!

            entry_request.register_failure!(
              I18n.t('internal.errors.messages.cancelled_by_customer')
            )
            fail_related_entities
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
            ::Payments::Fiat::SafeCharge::Deposits::ModeVerifier.call(
              payment_method_code: response[:payment_method],
              entry_request:       entry_request
            )
          end

          def update_deposit_details!
            ::Payments::Fiat::SafeCharge::PaymentDetails::RequestHandler.call(
              entry_request: entry_request,
              payment_option_id: response[:userPaymentOptionId]
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

            ga_client.track_deposit_failure!

            entry_request.register_failure!(failed_with_reason_message)
            fail_related_entities
          end

          def track_and_complete!
            ga_client.track_deposit_success!

            complete_entry_request!
          end

          def approved?
            status == APPROVED && payment_message_status == OK
          end

          def complete_entry_request!
            return if entry_request.succeeded?

            ::EntryRequests::DepositService.call(entry_request: entry_request)
          end

          def throw_unknown_status
            raise ::Payments::NotSupportedError,
                  "Unknown response status #{status}"
          end

          def failed_with_reason_message
            I18n.t('internal.errors.messages.payment_failed_with_reason_error',
                   reason: response[:Reason])
          end
        end
      end
    end
  end
end
