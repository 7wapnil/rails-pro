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
          callback_handler.call(response)
        end

        private

        attr_reader :request

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
