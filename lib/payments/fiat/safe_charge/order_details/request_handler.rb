# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module OrderDetails
        class RequestHandler < ApplicationService
          include Statuses
          include ErrorCodes

          def initialize(transaction:, order_id:)
            @transaction = transaction
            @order_id = order_id
          end

          def call
            log_response
            return unsuccessful_request_error_message unless success?

            error_message
          end

          private

          attr_reader :transaction, :order_id

          # rubocop:disable Metrics/MethodLength
          def log_response
            log_payload = response
                          .slice('totalCount', 'status', 'version')
                          .transform_keys { |key| "sc_#{key}".to_sym }
            withdrawal_orders = Array.wrap(response['withdrawalOrders'])

            Rails.logger.info(
              message: 'Payout order details request',
              sc_order_id: order_id,
              sc_request_id: transaction.id,
              sc_withdrawal_order_1: withdrawal_order_log(withdrawal_orders[0]),
              sc_withdrawal_order_2: withdrawal_order_log(withdrawal_orders[1]),
              sc_withdrawal_order_3: withdrawal_order_log(withdrawal_orders[2]),
              **log_payload
            )
          rescue StandardError => error
            Rails.logger.error(
              message: 'Payout order details request cannot be logged',
              sc_order_id: order_id,
              sc_request_id: transaction.id,
              error_object: error
            )
          end
          # rubocop:enable Metrics/MethodLength

          # rubocop:disable Metrics/MethodLength
          def withdrawal_order_log(payload)
            return unless payload

            log_payload = payload.slice(
              'wdOrderId', 'userPMId', 'amount', 'currency', 'settlementType',
              'wdOrderStatus', 'gwTrxId', 'errorCode', 'extendedErrorCode',
              'reasonCode', 'apmTrxId', 'creationData', 'lastModifiedDate',
              'pmName', 'pmIssuer', 'gwReason', 'gwStatus'
            ).transform_keys { |key| "sc_#{key}".to_sym }

            wd_request_payload = payload.fetch('wdRequest', {}).slice(
              'userTokenId', 'wdRequestId', 'merchantWDRequestId',
              'userPMId', 'requestedAmount', 'requestedCurrency',
              'state', 'wdRequestStatus', 'creationDate',
              'lastModifiedDate', 'dueDate', 'wdRequestOrderCount',
              'pmName', 'pmIssuer', 'approvedAmount'
            )

            {
              sc_wdRequest: wd_request_payload,
              **log_payload
            }
          end
          # rubocop:enable Metrics/MethodLength

          def unsuccessful_request_error_message
            return response['reason'] unless response['reason'].blank?
            return response['gwReason'] unless response['gwReason'].blank?

            default_error_message
          end

          def success?
            response.ok? && success_request?
          end

          def error_message
            return default_error_message unless gateway_error?

            error_message_by_code(order_details['extendedErrorCode'])
          end

          def response
            @response ||= client.receive_order_details(order_params)
          end

          def default_error_message
            I18n.t('errors.messages.withdrawal.no_order_details', id: order_id)
          end

          def client
            Client.new
          end

          def order_params
            RequestBuilder.call(
              transaction: transaction,
              order_id: order_id
            )
          end

          def success_request?
            response['status'] == SUCCESS
          end

          def gateway_error?
            return false unless order_details

            order_details['errorCode'] == GATEWAY_FILTER_ERROR_CODE
          end

          def order_details
            response['withdrawalOrders'].find do |order|
              order['wdOrderId'] == order_id
            end
          end
        end
      end
    end
  end
end
