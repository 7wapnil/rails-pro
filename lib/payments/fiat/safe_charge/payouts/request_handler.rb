# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class RequestHandler < Handlers::PayoutRequestHandler
          include Statuses

          delegate :withdrawal, to: :transaction

          def call
            Payouts::CallbackHandler.call(
              withdrawal: withdrawal,
              status: external_status,
              external_id: response['wdRequestId'],
              message: error_message
            )
          end

          private

          def external_status
            succeeded_request? && approved?
          end

          def response
            @response ||= client.authorize_payout(payout_params)
          end

          def error_message
            @error_message ||= "SafeCharge: #{response['reason']}"
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
            assign_custom_error_message(error)
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

          def assign_custom_error_message(error)
            @error_message = "#{error.class}: #{error.message}"
          end
        end
      end
    end
  end
end
