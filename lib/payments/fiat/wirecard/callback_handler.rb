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
          payload = response.dig('payment')

          Rails.logger.info(
            message: 'Wirecard callback',
            payment_type: payment_type,
            transaction: {
              id: payload['transaction-id'],
              type: payload['transaction-type'],
              state: payload['transaction-state']
            },
            parent_transaction_id: payload['parent-transaction-id'],
            status_1: payload.dig('statuses', 'status', 0),
            status_2: payload.dig('statuses', 'status', 1),
            status_3: payload.dig('statuses', 'status', 2),
            external_request_id: payload['request-id'].split(':').first,
            request_id: payload['request-id'],
            completion_timestamp: payload['completion-time-stamp'],
            requested_amount: payload['requested-amount'],
            payment_method: payload.dig('payment-methods', 'payment-method', 0),
            pending_redirect_url: payload['pending-redirect-url'],
            success_redirect_url: payload['success-redirect-url'],
            cancel_redirect_url: payload['cancel-redirect-url'],
            fail_redirect_url: payload['fail-redirect-url'],
            processing_redirect_url: payload['processing-redirect-url']
          )
        rescue StandardError
          Rails.logger.error(message: 'Wirecard callback cannot be logged')
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
