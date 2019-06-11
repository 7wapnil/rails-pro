# frozen_string_literal: true

module Webhooks
  module SafeCharge
    class CancelledPaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token

      def show
        ::Payments::SafeCharge::Provider.new.handle_payment_response(
          cancellation_params
        )

        redirect_to redirection_url
      end

      private

      def cancellation_params
        params.merge(Status: ::Payments::PaymentResponse::STATUS_CANCELLED)
      end

      def redirection_url
        ::Payments::SafeCharge::Webhooks::CallbackUrlBuilder.call(
          status: ::Payments::PaymentResponse::STATUS_CANCELLED
        )
      end
    end
  end
end
