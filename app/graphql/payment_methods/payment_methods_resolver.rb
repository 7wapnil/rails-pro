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
      deposit_entry_requests
        .pluck(:mode)
        .uniq
        .compact
        .flat_map(&method(:withdrawal_methods_for))
        .uniq
        .compact
    end

    def withdrawal_methods_for(payment_method)
      SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES[payment_method]
    end
  end
end
