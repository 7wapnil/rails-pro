# frozen_string_literal: true

module Payments
  module Wirecard
    class RequestBuilder < ApplicationService
      include ::Payments::Methods
      include Rails.application.routes.url_helpers

      attr_reader :transaction

      def initialize(transaction)
        @transaction = transaction
      end

      private

      def request_id
        "#{transaction.id}:#{Time.zone.now}"
      end

      def webhook_url
        webhooks_wirecard_payment_url(
          host: ENV['APP_HOST'],
          protocol: :https,
          request_id: transaction.id,
          signature: signature
        )
      end

      def signature
        OpenSSL::HMAC.hexdigest(
          SignatureVerifier::SIGNATURE_ALGORITHM,
          ENV['WIRECARD_SECRET_KEY'],
          transaction.id.to_s
        )
      end

      def payment_method
        {
          'payment-method': [
            { 'name': provider_method_name(transaction.method) }
          ]
        }
      end
    end
  end
end
