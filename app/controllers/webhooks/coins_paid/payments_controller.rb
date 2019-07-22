# frozen_string_literal: true

module Webhooks
  module CoinsPaid
    class PaymentsController < ActionController::Base
      before_action :verify_payment_signature, only: :create
      skip_before_action :verify_authenticity_token

      NO_LOGS_ERRORS = [
        ::Payments::BusinessRuleError,
        ::Payments::InvalidTransactionError
      ].freeze

      def create
        ::Payments::Crypto::CoinsPaid::CallbackHandler.call(request)

        head :ok
      rescue ::Payments::GatewayError => error
        Rails.logger.error(message: error.message)
        head :internal_server_error
      rescue *NO_LOGS_ERRORS
        head :ok
      rescue StandardError => error
        Rails.logger.error(message: error.message)
        head :ok
      end

      private

      def verify_payment_signature
        signature = Payments::Crypto::CoinsPaid::SignatureService.call(
          data: request.body.try(:string).to_s
        )

        valid = signature.present? &&
                signature == request.headers['X-Processing-Signature']

        return if valid

        raise ::Deposits::AuthenticationError,
              'Malformed CoinsPaid deposit request!'
      end
    end
  end
end
