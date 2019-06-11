# frozen_string_literal: true

module Webhooks
  module CoinsPaid
    class PaymentsController < ActionController::Base
      before_action :verify_payment_signature, only: :create
      skip_before_action :verify_authenticity_token

      def create
        ::Payments::CoinsPaid::Provider
          .new
          .handle_payment_response(request.body.string)

        head :ok
      rescue StandardError => _error
        head :internal_server_error
      end

      private

      def verify_payment_signature
        signature = Payments::SignatureService.call(data: request.body.string)

        result = signature.blank? ||
                 signature != request.headers['X-Processing-Signature']

        raise ::Deposits::AuthenticationError if result
      end
    end
  end
end
