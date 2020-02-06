# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class CallbackHandler < Handlers::PayoutCallbackHandler
          def initialize(withdrawal:, status:, response:, message: nil)
            @withdrawal = withdrawal
            @status = status
            @response = response
            @message = message
            @transaction_id = response['wdRequestId']
          end

          def call
            return succeeded! if status

            log_failure_response
            cancelled!(error_message)
            raise_payout_error!
          end

          private

          attr_reader :withdrawal, :status, :response, :transaction_id, :message

          def raise_payout_error!
            raise ::Withdrawals::PayoutError, error_message
          end

          def error_message
            @error_message ||= message || "SafeCharge: #{response['reason']}"
          end
        end
      end
    end
  end
end
