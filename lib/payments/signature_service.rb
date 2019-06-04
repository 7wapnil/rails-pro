# frozen_string_literal: true

module Payments
  class SignatureService < ApplicationService
    def initialize(data:)
      @data = data
    end

    def call
      digest = OpenSSL::Digest.new('sha512')

      OpenSSL::HMAC.hexdigest(digest,
                              ENV['COINSPAID_SECRET'],
                              @data)
    end
  end
end
