# frozen_string_literal: true

module Webhooks
  module SafeCharge
    class PaymentsController < ActionController::Base
      skip_before_action :verify_authenticity_token

      # rubocop:disable Metrics/MethodLength
      def create
        ::Payments::SafeCharge::Provider.new.handle_payment_response(params)

        callback_redirect_for(:success, 'Deposit was proceeded successfully')
      rescue ::Payments::CancelledError
        callback_redirect_for(
          :error, I18n.t('errors.messages.deposit_request_cancelled')
        )
      rescue ::Payments::FailedError
        callback_redirect_for(
          :error, I18n.t('errors.messages.deposit_request_failed')
        )
      rescue StandardError => error
        Rails.logger.error(message: 'Technical error appeared on deposit',
                           error: error.message)
        callback_redirect_for(
          :fail, I18n.t('errors.messages.technical_error_happened')
        )
      end
      # rubocop:enable Metrics/MethodLength

      private

      def callback_redirect_for(state, message = nil)
        redirect_to(
          ::Payments::SafeCharge::Webhooks::CallbackUrlBuilder.call(
            state: state,
            message: message
          )
        )
      end
    end
  end
end
