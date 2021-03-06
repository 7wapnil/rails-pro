# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class RequestHandler < Handlers::PayoutRequestHandler
          include Statuses

          delegate :withdrawal, to: :transaction

          def call
            log_response
            process_callback
          end

          private

          attr_reader :custom_error_message

          def log_response
            log_payload = response.slice(
              'version', 'status', 'errCode', 'reason', 'wdRequestStatus',
              'wdRequestId', 'merchantWDRequestId', 'userId', 'userAccountId'
            ).transform_keys { |key| "sc_#{key}" }

            Rails.logger.info(message: 'SafeCharge payout callback',
                              **log_payload.symbolize_keys)
          rescue StandardError => error
            Rails.logger.error(
              message: 'SafeCharge payout callback cannot be logged',
              sc_request_id: transaction.id,
              error_object: error
            )
          end

          def process_callback
            Payouts::CallbackHandler.call(
              withdrawal: withdrawal,
              status: external_status,
              response: response,
              message: custom_error_message
            )
          end

          def external_status
            succeeded_request? && approved?
          end

          def response
            @response ||= client.authorize_payout(payout_params)
          end

          def succeeded_request?
            response.ok? && succeeded_response?
          end

          def approved?
            PayoutApprovals::RequestHandler.call(
              transaction: transaction,
              withdrawal_id: response['wdRequestId']
            )
          rescue ::SafeCharge::ApprovingError => error
            assign_custom_error_message!(error)
            false
          end

          def succeeded_response?
            response['status'] == SUCCESS
          end

          def client
            Client.new
          end

          def payout_params
            RequestBuilder.call(transaction: transaction)
          end

          def assign_custom_error_message!(error)
            @custom_error_message = "#{error.class}: #{error.message}"
          end
        end
      end
    end
  end
end
