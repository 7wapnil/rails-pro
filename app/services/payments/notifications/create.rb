# frozen_string_literal: true

module Payments
  module Notifications
    class Create < ApplicationService
      def initialize(params = {})
        @params = params
        @payment_method = params.delete(:method)
      end

      def call
        verify_payment_method!

        provider.handle_payment_response(params)
      end

      private

      attr_reader :params, :payment_method

      def verify_payment_method!
        return if Payments::Methods::METHOD_PROVIDERS.key?(payment_method)

        raise "Payment method is not supported: #{payment_method}"
      end

      def provider
        Payments::Methods::METHOD_PROVIDERS.dig(payment_method, :provider).new
      end
    end
  end
end
