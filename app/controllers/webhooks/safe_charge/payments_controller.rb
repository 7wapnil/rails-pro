# frozen_string_literal: true

module Webhooks
  module SafeCharge
    class PaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :verify_payment_signature

      def show
        redirect_to success_redirection_url
      end

      def create
        ::Payments::SafeCharge::Provider.new.handle_deposit_response(params)

        head :ok
      rescue ::Payments::FailedError
        head :unprocessable_entity
      rescue StandardError => error
        Rails.logger.error(message: 'Technical error appeared on deposit',
                           error: error.message)

        head :internal_server_error
      end

      private

      def verify_payment_signature
        return if ::Payments::SafeCharge::SignatureVerifier.call(params)

        raise ::Deposits::AuthenticationError,
              'Malformed SafeCharge deposit request!'
      end

      def success_redirection_url
        ::Payments::Webhooks::DepositRedirectionUrlBuilder.call(
          status: ::Payments::Webhooks::Statuses::SUCCESS
        )
      end
    end
  end
end
