# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class CallbackHandler < ::ApplicationService
        def initialize(response)
          @response = response
        end

        def call
          log_response
          callback_handler.call(response)
        end

        private

        attr_reader :response

        def log_response
          return log_cancellation_response if cancellation_callback?

          log_deposit_response
        end

        def cancellation_callback?
          response['Status'] == ::Payments::Webhooks::Statuses::CANCELLED
        end

        def log_cancellation_response
          Rails.logger.info(
            message: 'SafeCharge deposit cancellation callback',
            sc_request_id: response['request_id'],
            sc_signature: response['signature']
          )
        end

        # rubocop:disable Metrics/MethodLength
        def log_deposit_response
          log_payload = response.slice(
            'APMReferenceID', 'Cvv2Reply', 'ErrCode', 'ExErrCode',
            'PPP_TransactionID', 'Reason', 'ReasonCode', 'Status',
            'TransactionID', 'advanceResponseChecksum', 'client_ip',
            'currency', 'country', 'errApmCode', 'errApmDescription',
            'errScCode', 'errScDescription', 'externalTransactionId',
            'feeAmount', 'item_amount_1', 'item_name_1', 'item_quantity_1',
            'message', 'orderTransactionId', 'payment_method', 'ppp_status',
            'responseTimeStamp', 'responsechecksum', 'totalAmount',
            'transactionType', 'type', 'unknownParameters', 'request_id',
            'upoRegistrationDate', 'userid', 'userPaymentOptionId'
          ).to_h.transform_keys { |key| "sc_#{key}".to_sym }

          Rails.logger.info(
            message: 'SafeCharge deposit callback',
            **log_payload
          )
        end
        # rubocop:enable Metrics/MethodLength

        def callback_handler
          ::Payments::Fiat::SafeCharge::Deposits::CallbackHandler
        end
      end
    end
  end
end
