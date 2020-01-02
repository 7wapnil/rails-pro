# frozen_string_literal: true

module Webhooks
  module Wirecard
    class PaymentsController < ActionController::Base
      include ::Payments::Webhooks::Statuses

      skip_before_action :verify_authenticity_token
      before_action :verify_payment_signature

      def create
        ::Payments::Fiat::Wirecard::CallbackHandler.call(request)

        redirect_to callback_redirect_for(SUCCESS)
      rescue ::Payments::CancelledError
        redirect_to callback_redirect_for(CANCELLED)
      rescue ::Payments::FailedError => error
        message = error.message if error.humanized?

        redirect_to callback_redirect_for(FAILED, custom_message: message)
      rescue StandardError => error
        Rails.logger.error(message: 'Technical error appeared on deposit',
                           error_object: error)

        redirect_to callback_redirect_for(SYSTEM_ERROR)
      end

      private

      def verify_payment_signature
        return if ::Payments::Fiat::Wirecard::SignatureVerifier.call(params)

        raise ::Deposits::AuthenticationError,
              'Malformed Wirecard deposit request!'
      end

      def callback_redirect_for(status, custom_message: nil)
        ::Payments::Webhooks::DepositRedirectionUrlBuilder.call(
          status: status,
          request_id: params[:request_id],
          custom_message: custom_message
        )
      end
    end
  end
end
