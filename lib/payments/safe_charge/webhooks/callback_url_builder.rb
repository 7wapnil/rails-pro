# frozen_string_literal: true

module Payments
  module SafeCharge
    module Webhooks
      class CallbackUrlBuilder < ApplicationService
        STATES_MAP = {
          ::Payments::PaymentResponse::STATUS_SUCCESS => :success,
          ::Payments::PaymentResponse::STATUS_CANCELLED => :error
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
          when ::Payments::PaymentResponse::STATUS_SUCCESS
            I18n.t('webhooks.safe_charge.redirections.success_message')
          when ::Payments::PaymentResponse::STATUS_CANCELLED
            I18n.t('errors.messages.deposit_request_cancelled')
          end
        end
      end
    end
  end
end
