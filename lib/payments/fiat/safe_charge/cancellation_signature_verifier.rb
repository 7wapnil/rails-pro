# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class CancellationSignatureVerifier < ApplicationService
        SIGNATURE_ALGORITHM = 'sha256'

        def initialize(params = {})
          @params = params
        end

        def call
          signature == params['signature']
        end

        private

        attr_reader :params

        def signature
          @signature ||= OpenSSL::HMAC.hexdigest(
            SIGNATURE_ALGORITHM,
            ENV['SAFECHARGE_SECRET_KEY'],
            params[:request_id].to_s
          )
        end
      end
    end
  end
end
