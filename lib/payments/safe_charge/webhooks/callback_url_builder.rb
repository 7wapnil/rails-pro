# frozen_string_literal: true

module Payments
  module SafeCharge
    module Webhooks
      class CallbackUrlBuilder < ApplicationService
        REQUEST_FAILED_MESSAGE =
          I18n.t('errors.messages.deposit_request_failed')
        REQUEST_MESSAGE_CANCELLED_MESSAGE =
          I18n.t('errors.messages.deposit_request_cancelled')
        SOMETHING_WENT_WRONG_MESSAGE =
          I18n.t('errors.messages.technical_error_happened')
        FAILED_ENTRY_REQUEST_MESSAGE =
          I18n.t('errors.messages.deposit_attempt_is_not_succeded')
        DEPOSIT_ATTEMPTS_EXCEEDED_MESSAGE =
          I18n.t('errors.messages.deposit_attempts_exceeded')

        def initialize(state:, message: nil)
          @state = state
          @message = message
        end

        def call
          URI("#{ENV['FRONTEND_URL']}?#{query_params}").to_s
        end

        private

        attr_reader :state, :message

        def query_params
          URI.encode_www_form(
            depositState: state,
            depositStateMessage: message
          )
        end
      end
    end
  end
end
