# frozen_string_literal: true

module Webhooks
  module SafeCharge
    class PaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :verify_payment_signature

      def show
        redirect_to redirection_url
      end

      def create
        ::Payments::Fiat::SafeCharge::CallbackHandler.call(params)

        head :ok
      rescue ::Payments::FailedError
        head :unprocessable_entity
      rescue StandardError => error
        Rails.logger.error(message: 'Technical error appeared on deposit',
                           error_object: error.message)

        head :internal_server_error
      end

      private

      def verify_payment_signature
        return if ::Payments::Fiat::SafeCharge::SignatureVerifier.call(params)

        raise ::Deposits::AuthenticationError,
              'Malformed SafeCharge deposit request!'
      end

      def redirection_url
        ::Payments::Webhooks::DepositRedirectionUrlBuilder
          .call(status: redirection_status)
      end

      def redirection_status
        ::Payments::Fiat::SafeCharge::Statuses::REDIRECTION_MAP
          .fetch(params[:ppp_status], ::Payments::Webhooks::Statuses::FAILED)
      end
    end
  end
end
