# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module PayoutApprovals
        class RequestHandler < ApplicationService
          include Statuses

          def initialize(transaction:, withdrawal_id:)
            @transaction = transaction
            @withdrawal_id = withdrawal_id
          end

          def call
            log_response
            return true if success?

            raise ::SafeCharge::ApprovingError, error_message
          end

          private

          attr_reader :transaction, :withdrawal_id

          # rubocop:disable Metrics/MethodLength
          def log_response
            log_payload = response.slice(
              'version', 'status', 'errCode', 'reason', 'wdRequestStatus',
              'wdOrderStaus', 'wdOrderStatus', 'wdRequestId', 'wdOrderId',
              'merchantWDRequestId', 'userAccountId'
            ).transform_keys { |key| "sc_#{key}" }

            Rails.logger.info(
              message: 'SafeCharge payout approval',
              **log_payload.symbolize_keys
            )
          rescue StandardError => error
            Rails.logger.error(
              message: 'SafeCharge payout approval cannot be logged',
              sc_request_id: transaction.id,
              error_object: error
            )
          end
          # rubocop:enable Metrics/MethodLength

          def response
            @response ||= client.approve_payout(approve_params)
          end

          def success?
            response.ok? && success_request? && approved?
          end

          def error_message
            return response['reason'] unless response['reason'].blank?
            return default_error_message if response['wdOrderId'].blank?

            OrderDetails::RequestHandler.call(
              transaction: transaction,
              order_id: response['wdOrderId']
            )
          end

          def client
            Client.new
          end

          def approve_params
            RequestBuilder.call(
              transaction: transaction,
              withdrawal_id: withdrawal_id
            )
          end

          def success_request?
            response['status'] == SUCCESS
          end

          def approved?
            response['wdRequestStatus'] == PAYOUT_APPROVED
          end

          def default_error_message
            I18n.t('internal.errors.messages.withdrawal.confirmation_error')
          end
        end
      end
    end
  end
end
