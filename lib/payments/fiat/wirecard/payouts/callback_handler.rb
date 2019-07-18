# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      module Payouts
        class CallbackHandler < Handlers::PayoutCallbackHandler
          include Statuses

          def initialize(response)
            @response = response
          end

          def call
            return succeeded! if confirmed?

            cancelled!(error_message)
          end

          private

          def confirmed?
            status_code == CONFIRMED
          end

          def status_code
            response.dig('payment', 'statuses', 'status', 'code').to_i
          end

          def error_message
            response.dig('payment', 'statuses', 'status', 'description')
          end

          def request_id
            @request_id ||=
              response.dig('payment', 'request-id').to_s.split(':').first.to_i
          end

          def transactions_id
            response.dig('payment', 'transaction-id')
          end
        end
      end
    end
  end
end
