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

      def initialize(status:)
        @status = status
      end

      def call
        URI("#{ENV['FRONTEND_URL']}?#{query_params}").to_s
      end

      private

      attr_reader :status

      def query_params
        URI.encode_www_form(depositState: state, depositStateMessage: message)
      end

      def state
        STATES_MAP[status]
      end

      def message
        case status
        when ::Payments::Webhooks::Statuses::SUCCESS
          I18n.t('webhooks.safe_charge.redirections.success_message')
        when ::Payments::Webhooks::Statuses::CANCELLED
          I18n.t('errors.messages.deposit_request_cancelled')
        when ::Payments::Webhooks::Statuses::FAILED
          I18n.t('errors.messages.deposit_request_failed')
        when ::Payments::Webhooks::Statuses::SYSTEM_ERROR
          I18n.t('errors.messages.technical_error_happened')
        end
      end
    end
  end
end
