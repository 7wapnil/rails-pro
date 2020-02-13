# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class RedirectHandler < ApplicationService
        def initialize(params)
          @params = params.to_h
        end

        # rubocop:disable Metrics/MethodLength
        def call
          log_payload = params.slice(
            'ClientUniqueID', 'ErrCode', 'Error', 'ExErrCode',
            'PPP_TransactionID', 'Status', 'TransactionID',
            'advanceResponseChecksum', 'currency', 'item_amount_1',
            'item_quantity_1', 'merchantLocale', 'message',
            'orderTransactionId', 'payment_method', 'ppp_status', 'productId',
            'requestVersion', 'request_id', 'responseTimeStamp',
            'responsechecksum', 'totalAmount', 'userPaymentOptionId', 'userid'
          ).transform_keys { |key| "sc_#{key}" }

          Rails.logger.info(
            message: 'SafeCharge redirect callback',
            **log_payload.symbolize_keys
          )
        rescue StandardError => error
          Rails.logger.error(
            message: 'SafeCharge redirect callback cannot be logged',
            sc_request_id: params['request_id'],
            error_object: error
          )
        end
        # rubocop:enable Metrics/MethodLength

        private

        attr_reader :params
      end
    end
  end
end
