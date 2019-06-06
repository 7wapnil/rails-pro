# frozen_string_literal: true

module Webhooks
  module CoinsPaid
    class PaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token

      def create
        ::Payments::CoinsPaid::Provider.new.handle_payment_response(params)

        head :ok
      rescue StandardError => _error
        head :internal_server_error
      end
    end
  end
end
