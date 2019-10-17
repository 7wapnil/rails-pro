# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class CallbackHandler < Handlers::PayoutCallbackHandler
          def initialize(withdrawal:, status:, external_id: nil, message: nil)
            @withdrawal = withdrawal
            @status = status
            @transaction_id = external_id
            @message = message
          end

          def call
            return succeeded! if status

            cancelled!(message)
            raise_payout_error!
          end

          private

          attr_reader :withdrawal, :status, :transaction_id, :message

          def raise_payout_error!
            raise ::Withdrawals::PayoutError, message
          end
        end
      end
    end
  end
end
