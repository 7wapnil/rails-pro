# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      module Payouts
        class RequestHandler < Handlers::PayoutRequestHandler
          include Statuses

          private

          # rubocop:disable Metrics/MethodLength
          def log_response
            payload = response.dig('payment')
            payment_method = payload.dig('payment-methods', 'payment-method', 0)
            status_payload = Array.wrap(payload.dig('statuses', 'status'))

            Rails.logger.info(
              message: 'Wirecard payout request',
              transaction: {
                id: payload['transaction-id'],
                type: payload['transaction-type'],
                state: payload['transaction-state']
              },
              parent_transaction_id: payload['parent-transaction-id'],
              status_1: status_payload[0],
              status_2: status_payload[1],
              status_3: status_payload[2],
              external_request_id: "id:#{payload['request-id']}",
              request_id: payload['request-id'].split(':').first,
              completion_timestamp: payload['completion-time-stamp'],
              requested_amount: payload['requested-amount'],
              payment_method: payment_method
            )
          rescue StandardError
            Rails.logger.error(
              message: 'Wirecard payout request cannot be logged'
            )
          end
          # rubocop:enable Metrics/MethodLength

          def created?
            succeeded_request? && succeeded_response?
          end

          def succeeded_request?
            request.code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
          end

          def succeeded_response?
            status_code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
          end

          def status_code
            response.dig('payment', 'statuses', 'status', 0, 'code').to_i
          end

          def client
            ::Payments::Fiat::Wirecard::Client.new
          end

          def request
            @request ||= client.authorize_payout(transaction)
          end

          def response
            @response ||= JSON.parse(request.body)
          end

          def raw_error_message
            return request.message unless succeeded_request?

            response.dig('payment', 'statuses', 'status', 0, 'description')
          end

          def error_message
            @error_message ||= "Wirecard: #{raw_error_message}"
          end
        end
      end
    end
  end
end
