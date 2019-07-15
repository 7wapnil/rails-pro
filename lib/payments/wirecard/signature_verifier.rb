# frozen_string_literal: true

module Payments
  module Wirecard
    class SignatureVerifier < ApplicationService
      SIGNATURE_ALGORITHM = 'sha256'

      def initialize(params = {})
        @our_signature = params[:signature]
        @request_id = params[:request_id].to_s
        @signature = params['response-signature-base64'].to_s
        @data = params['response-base64']
      end

      def call
        (data.nil? || encoded_signature == decoded_response_signature) &&
          encoded_request_id == our_signature
      end

      private

      attr_reader :our_signature, :request_id, :signature, :data

      def encoded_signature
        OpenSSL::HMAC.digest(
          SIGNATURE_ALGORITHM,
          ENV['WIRECARD_SECRET_KEY'],
          data
        )
      end

      def decoded_response_signature
        Base64.decode64(signature)
      end

      def encoded_request_id
        OpenSSL::HMAC.hexdigest(
          SIGNATURE_ALGORITHM,
          ENV['WIRECARD_SECRET_KEY'],
          request_id
        )
      end
    end
  end
end
