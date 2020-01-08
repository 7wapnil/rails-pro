# frozen_string_literal: true

module Payments
  module Webhooks
    class DepositRedirectionUrlBuilder < ApplicationService
      STATES_MAP = {
        ::Payments::Webhooks::Statuses::SUCCESS => :success,
        ::Payments::Webhooks::Statuses::CANCELLED => :error,
        ::Payments::Webhooks::Statuses::FAILED => :fail,
        ::Payments::Webhooks::Statuses::SYSTEM_ERROR => :fail
      }.freeze

      def initialize(status:, custom_message: nil)
        @status = status
        @custom_message = custom_message
      end

      def call
        URI("#{ENV['FRONTEND_URL']}?#{query_params}").to_s
      end

      private

      attr_reader :status, :custom_message

      def query_params
        URI.encode_www_form(
          depositState: state,
          depositStateMessage: custom_message || general_message
        )
      end

      def state
        STATES_MAP[status]
      end

      def general_message
        case status
        when ::Payments::Webhooks::Statuses::SUCCESS
          I18n.t('webhooks.safe_charge.redirections.success_message')
        when ::Payments::Webhooks::Statuses::CANCELLED
          I18n.t('errors.messages.deposit_cancelled')
        when ::Payments::Webhooks::Statuses::FAILED
          I18n.t('errors.messages.deposit_failed')
        when ::Payments::Webhooks::Statuses::SYSTEM_ERROR
          I18n.t('errors.messages.technical_error_happened')
        end
      end
    end
  end
end
