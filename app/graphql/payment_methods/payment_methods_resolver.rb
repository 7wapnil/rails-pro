# frozen_string_literal: true

module PaymentMethods
  class PaymentMethodsResolver < ApplicationService
    def initialize(current_customer:)
      @current_customer = current_customer
    end

    def call
      payment_methods
    end

    private

    attr_reader :current_customer

    def deposit_entry_requests
      @deposit_entry_requests ||= current_customer
                                  .entry_requests
                                  .deposit
                                  .succeeded
    end

    def payment_methods
      deposit_entry_requests.pluck(:mode).uniq.compact
    end
  end
end
