# frozen_string_literal: true

module Payments
  module Wirecard
    class SignatureVerifier < ApplicationService
      SIGNATURE_ALGORITHM = 'sha256'

      def initialize(params = {})
        @signature = params['response-signature-base64']
        @data = params['response-base64']
      end

      def call
        encode_signature == decoded_response_signature
      end

      private

      attr_reader :signature, :data

      def encode_signature
        OpenSSL::HMAC.digest(
          SIGNATURE_ALGORITHM,
          ENV['WIRECARD_SECRET_KEY'],
          data
        )
      end

      def decoded_response_signature
        Base64.decode64(signature)
      end
    end
  end
end
