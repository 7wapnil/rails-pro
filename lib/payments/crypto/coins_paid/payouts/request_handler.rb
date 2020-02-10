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
            transaction_payload = response.dig('transactions', 0).slice(
              'id', 'currency', 'transaction_type', 'type', 'tag',
              'amount', 'txid', 'riskscore', 'confirmations'
            )

            Rails.logger.info(
              message: 'CoinsPaid payout request',
              id: response['id'],
              type: payment_type,
              foreign_id: response['foreign_id'],
              currency_sent: response['currency_sent'],
              currency_received: response['currency_received'],
              transactions: transaction_payload,
              fees: response.dig('fees', 0),
              external_error: response['error'],
              external_status: response['status']
            )
          rescue StandardError
            Rails.logger.error(
              message: 'CoinsPaid payout request cannot be logged'
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
