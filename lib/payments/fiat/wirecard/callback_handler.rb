# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      class CallbackHandler < ::ApplicationService
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
          @response ||= case payment_type
                        when ::Deposit.name
                          base64_response
                        when ::Withdrawal.name
                          xml_response
                        else
                          non_supported_payment_type!
                        end
        end

        def request_id
          request.params['request_id']
        end

        def payment_type
          @payment_type ||= CustomerTransaction
                            .joins(:entry_request)
                            .find_by!(entry_requests: { id: request_id })
                            .type
        end

        def base64_response
          return stub_response unless request.params.key?('response-base64')

          JSON.parse(Base64.decode64(request.params['response-base64']))
        end

        def xml_response
          Hash
            .from_xml(request.body.string)
            .deep_transform_keys { |key| key.tr('_', '-') }
        end

        def callback_handler
          case payment_type
          when ::Deposit.name
            ::Payments::Fiat::Wirecard::Deposits::CallbackHandler
          when ::Withdrawal.name
            ::Payments::Fiat::Wirecard::Payouts::CallbackHandler
          else
            non_supported_payment_type!
          end
        end

        def stub_response
          { 'payment' => { 'request-id' => request_id } }
        end

        def non_supported_payment_type!
          raise ::Payments::NotSupportedError, 'Non supported payment type'
        end
      end
    end
  end
end
