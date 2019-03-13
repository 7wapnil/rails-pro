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

    def entries
      @entries ||= current_customer.entry_requests.succeeded
    end

    def payment_methods
      entries.pluck(:mode).uniq
    end
  end
end
