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

      delegate :currency, to: :entry_request, allow_nil: true

      def initialize(status:, request_id:, custom_message: nil)
        @status = status
        @request_id = request_id
        @custom_message = custom_message
      end

      def call
        URI("#{ENV['FRONTEND_URL']}?#{query_params}").to_s
      end

      private

      attr_reader :status, :request_id, :custom_message

      def query_params
        URI.encode_www_form(
          depositState: state,
          depositStateMessage: custom_message || general_message,
          depositDetails: base_64_deposit_summary
        )
      end

      def state
        STATES_MAP[status]
      end

      def general_message
        case status
        when ::Payments::Webhooks::Statuses::SUCCESS
          I18n.t('messages.success_deposit')
        when ::Payments::Webhooks::Statuses::CANCELLED
          I18n.t('errors.messages.deposit_cancelled')
        when ::Payments::Webhooks::Statuses::FAILED
          I18n.t('errors.messages.deposit_failed')
        when ::Payments::Webhooks::Statuses::SYSTEM_ERROR
          I18n.t('errors.messages.technical_error_happened')
        end
      end

      def base_64_deposit_summary
        Base64.encode64(URI.encode_www_form(deposit_summary))
      end

      def deposit_summary
        return {} unless entry_request

        {
          realMoneyAmount: entry_request.real_money_amount,
          bonusAmount: entry_request.bonus_amount,
          paymentMethod: entry_request.mode,
          currencyCode: currency&.code
        }
      end

      def entry_request
        @entry_request ||= EntryRequest.find_by(id: request_id)
      end
    end
  end
end
