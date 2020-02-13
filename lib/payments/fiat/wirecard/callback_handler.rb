# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      class CallbackHandler < ::ApplicationService
        DEPOSIT = 'purchase'
        WITHDRAWAL = Rails.env.production? ? 'original-credit' : 'credit'

        def initialize(request)
          @request = request
        end

        def call
          log_response
          callback_handler.call(response)
        end

        private

        attr_reader :request

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def log_response
          payload = response.fetch('payment', {})
          request_id = payload['request-id'].to_s.split(':').first
          status_payload = Array.wrap(payload.dig('statuses', 'status'))
          payment_method_payload = payload
                                   .dig('payment-methods', 'payment-method', 0)

          Rails.logger.info(
            message: 'Wirecard callback',
            wc_payment_type: payment_type,
            wc_transaction: {
              id: payload['transaction-id'],
              type: payload['transaction-type'],
              state: payload['transaction-state']
            },
            wc_parent_transaction_id: payload['parent-transaction-id'],
            wc_status_1: status_payload[0],
            wc_status_2: status_payload[1],
            wc_status_3: status_payload[2],
            wc_external_request_id: "id:#{payload['request-id']}",
            wc_request_id: request_id,
            wc_completion_timestamp: payload['completion-time-stamp'],
            wc_requested_amount: payload['requested-amount'],
            wc_payment_method: payment_method_payload,
            wc_pending_redirect_url: payload['pending-redirect-url'],
            wc_success_redirect_url: payload['success-redirect-url'],
            wc_cancel_redirect_url: payload['cancel-redirect-url'],
            wc_fail_redirect_url: payload['fail-redirect-url'],
            wc_processing_redirect_url: payload['processing-redirect-url']
          )
        rescue StandardError => error
          Rails.logger.error(
            message: 'Wirecard callback cannot be logged',
            wc_request_id: request_id,
            error_object: error
          )
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        def response
          @response ||= base64? ? base64_response : xml_response
        end

        def payment_type
          response.dig('payment', 'transaction-type')
        end

        def base64?
          request.params['response-base64'].present?
        end

        def base64_response
          JSON.parse(Base64.decode64(request.params['response-base64']))
        end

        def xml_response
          Hash
            .from_xml(request.body.string)
            .deep_transform_keys { |key| key.tr('_', '-') }
        end

        def callback_handler
          case payment_type
          when DEPOSIT
            ::Payments::Fiat::Wirecard::Deposits::CallbackHandler
          when WITHDRAWAL
            ::Payments::Fiat::Wirecard::Payouts::CallbackHandler
          else
            non_supported_payment_type!
          end
        end

        def non_supported_payment_type!
          raise ::Payments::NotSupportedError, 'Non supported payment type'
        end
      end
    end
  end
end
