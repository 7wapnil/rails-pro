# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class SignatureVerifier < ApplicationService
        def initialize(params = {})
          @params = params
        end

        def call
          signature.present? && signature == params['advanceResponseChecksum']
        end

        private

        attr_reader :params

        def signature
          @signature ||= Digest::SHA256.hexdigest(checksum_string)
        end

        def checksum_string
          [
            ENV['SAFECHARGE_SECRET_KEY'],
            params['totalAmount'],
            params['currency'],
            params['responseTimeStamp'],
            params['PPP_TransactionID'],
            params['Status'],
            params['productId']
          ].join
        end
      end
    end
  end
end
