module Deposits
  class PaymentPageUrlService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
    end
  end
end
