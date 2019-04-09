# frozen_string_literal: true

module PaymentMethods
  class PaymentMethodsResolver < ApplicationService
    def call
      payment_methods
    end

    private

    def payment_methods
      SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.values
                                                    .flatten
                                                    .compact
                                                    .uniq
    end
  end
end
