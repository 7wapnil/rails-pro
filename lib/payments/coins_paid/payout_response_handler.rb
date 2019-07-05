# frozen_string_literal: true

module Payments
  module CoinsPaid
    class PayoutResponseHandler < ::Payments::PayoutResponseHandler
      include Statuses

      def initialize(payout_request)
        @payout_request = payout_request
      end

      private

      attr_reader :payout_request

      def response
        @response = JSON.parse(payout_request.body)
      end

      def created?
        status_code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
      end

      def error_message
        @error_message ||= response['errors']&.values&.first
      end

      def status_code
        payout_request.code.to_i
      end

      def request_id
        response['foreign_id']
      end
    end
  end
end
