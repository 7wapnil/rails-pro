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

        def log_response
          Rails.logger.info(
            message: 'CoinsPaid callback',
            payment_type: payment_type,
            **response.deep_symbolize_keys
          )
        end

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
