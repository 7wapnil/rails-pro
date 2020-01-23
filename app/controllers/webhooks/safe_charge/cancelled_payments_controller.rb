# frozen_string_literal: true

module Webhooks
  module SafeCharge
    class CancelledPaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :verify_payment_signature

      def show
        ::Payments::Fiat::SafeCharge::CallbackHandler.call(
          cancellation_params
        )

        redirect_to redirection_url
      end

      private

      def verify_payment_signature
        valid = ::Payments::Fiat::SafeCharge::CancellationSignatureVerifier
                .call(params)

        return if valid

        raise ::Deposits::AuthenticationError,
              'Malformed SafeCharge deposit cancellation request!'
      end

      def cancellation_params
        params.merge(Status: ::Payments::Webhooks::Statuses::CANCELLED)
      end

      def redirection_url
        ::Payments::Webhooks::DepositRedirectionUrlBuilder.call(
          status: ::Payments::Webhooks::Statuses::CANCELLED,
          request_id: params[:request_id]
        )
      end
    end
  end
end
