# frozen_string_literal: true

module Payments
  class PaymentResponse < ::ApplicationService
    STATUS_SUCCESS = 'success'
    STATUS_FAILED = 'failed'
    STATUS_PENDING = 'pending'
    STATUS_CANCELLED = 'cancelled'
    STATUS_NOTIFICATION = 'notification'

    def initialize(response)
      @response = response
    end

    protected

    attr_reader :response
  end
end
