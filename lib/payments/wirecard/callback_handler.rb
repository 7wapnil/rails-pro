# frozen_string_literal: true

module Payments
  module Wirecard
    class CallbackHandler < ::ApplicationService
      DEPOSIT = 'authorization'
      WITHDRAWAL = 'credit'

      def initialize(request)
        @request = request
      end

      def call
        case payment_type
        when DEPOSIT
          ::Payments::Wirecard::Deposits::CallbackHandler.call(response)
        when WITHDRAWAL
          ::Payments::Wirecard::Payouts::CallbackHandler.call(response)
        end
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
    end
  end
end
