# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Payouts
        class CallbackHandler < Handlers::PayoutCallbackHandler
          include Statuses

          def call
            return succeeded! if confirmed?

            cancelled!(error_message)
          end

          private

          def confirmed?
            response['status'] == CONFIRMED
          end

          def error_message
            response['error']
          end

          def request_id
            response['foreign_id']
          end

          def transaction_id
            response.dig('transactions', 0, 'id')
          end
        end
      end
    end
  end
end
