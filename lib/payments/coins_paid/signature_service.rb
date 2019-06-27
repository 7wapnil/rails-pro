# frozen_string_literal: true

module Payments
  module CoinsPaid
    class SignatureService < ApplicationService
      SIGNATURE_ALGORITHM = 'sha512'

      def initialize(data:)
        @data = data
      end

      def call
        OpenSSL::HMAC
          .hexdigest(SIGNATURE_ALGORITHM, ENV['COINSPAID_SECRET'], data)
      end

      private

      attr_reader :data
    end
  end
end
