# frozen_string_literal: true

module Webhooks
  module Wirecard
    class PaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :verify_payment_signature

      def create
        ::Payments::Fiat::Wirecard::CallbackHandler.call(request)

        callback_redirect_for(::Payments::Webhooks::Statuses::SUCCESS)
      rescue ::Payments::CancelledError
        callback_redirect_for(::Payments::Webhooks::Statuses::CANCELLED)
      rescue ::Payments::FailedError
        callback_redirect_for(::Payments::Webhooks::Statuses::FAILED)
      rescue StandardError => error
        Rails.logger.error(message: 'Technical error appeared on deposit',
                           error: error.message)

        callback_redirect_for(::Payments::Webhooks::Statuses::SYSTEM_ERROR)
      end

      private

      def verify_payment_signature
        return if ::Payments::Fiat::Wirecard::SignatureVerifier.call(params)

        raise ::Deposits::AuthenticationError,
              'Malformed Wirecard deposit request!'
      end

      def callback_redirect_for(status)
        redirect_to(
          ::Payments::Webhooks::DepositRedirectionUrlBuilder
            .call(status: status)
        )
      end
    end
  end
end
