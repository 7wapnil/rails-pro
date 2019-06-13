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
        params.merge(Status: ::Payments::Webhooks::Statuses::CANCELLED)
      end

      def redirection_url
        ::Payments::Webhooks::DepositRedirectionUrlBuilder.call(
          status: ::Payments::Webhooks::Statuses::CANCELLED
        )
      end
    end
  end
end
