# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      class CallbackHandler < ::ApplicationService
        DEPOSIT = 'deposit'
        WITHDRAWAL = 'withdrawal'

        def initialize(request)
          @request = request
        end

        def call
          log_response
          callback_handler.call(response)
        end

        private

        attr_reader :request

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def log_response
          crypto_address_payload = response['crypto_address']
                                   .slice('id', 'currency', 'foreign_id', 'tag')
          transaction_payload = response.dig('transactions', 0).slice(
            'id', 'currency', 'transaction_type', 'type', 'tag',
            'amount', 'txid', 'riskscore', 'confirmations'
          )

          Rails.logger.info(
            message: 'CoinsPaid callback',
            cp_id: response['id'],
            cp_type: payment_type,
            cp_crypto_address: crypto_address_payload,
            cp_currency_sent: response['currency_sent'],
            cp_currency_received: response['currency_received'],
            cp_transactions: transaction_payload,
            cp_fees: response.dig('fees', 0),
            cp_error: response['error'],
            cp_status: response['status']
          )
        rescue StandardError => error
          Rails.logger.error(
            message: 'CoinsPaid callback cannot be logged',
            cp_id: response['id'],
            error_object: error
          )
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        def response
          @response ||= JSON.parse(request.body.string)
        end

        def payment_type
          response['type']
        end

        def callback_handler
          case payment_type
          when DEPOSIT
            ::Payments::Crypto::CoinsPaid::Deposits::CallbackHandler
          when WITHDRAWAL
            ::Payments::Crypto::CoinsPaid::Payouts::CallbackHandler
          else
            non_supported_payment_type!
          end
        end

        def non_supported_payment_type!
          raise ::Payments::GatewayError, 'Non supported payment type'
        end
      end
    end
  end
end
