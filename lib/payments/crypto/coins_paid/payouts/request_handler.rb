# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Payouts
        class RequestHandler < Handlers::PayoutRequestHandler
          include Statuses

          private

          # rubocop:disable Metrics/MethodLength
          def log_response
            log_payload = response.fetch('data', {}).slice(
              'id', 'foreign_id', 'type', 'amount', 'sender_amount',
              'sender_currency', 'receiver_amount', 'receiver_currency'
            )
            response_errors = Array.wrap(response['errors'])

            Rails.logger.info(
              message: 'CoinsPaid payout request',
              external_status: response['status'],
              response_error_1: response_errors[0],
              response_error_2: response_errors[1],
              response_error_3: response_errors[2],
              **log_payload.deep_symbolize_keys
            )
          rescue StandardError
            Rails.logger.error(
              message: 'CoinsPaid payout request cannot be logged',
              system_request_id: transaction.id
            )
          end
          # rubocop:enable Metrics/MethodLength

          def created?
            status_code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
          end

          def status_code
            request.code.to_i
          end

          def client
            ::Payments::Crypto::CoinsPaid::Client.new
          end

          def request
            @request ||= client.authorize_payout(transaction)
          end

          def response
            @response ||= JSON.parse(request.body)
          rescue JSON::ParserError, TypeError
            {}
          end

          def raw_error_message
            response['errors']&.values&.first
          end

          def error_message
            @error_message ||= "CoinsPaid: #{raw_error_message}"
          end
        end
      end
    end
  end
end
