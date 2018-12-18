module CustomerBonuses
  class ExpirationService < ApplicationService
    def initialize(customer_bonus, expiration_reason)
      @customer = customer_bonus.customer
      @customer_bonus = customer_bonus
      @expiration_reason = expiration_reason
    end

    def call
      expire_bonus!
      @customer_bonus
    end

    private

    attr_accessor :customer_bonus, :expiration_reason

    def expire_bonus!
      @customer_bonus.update!(expiration_reason: @expiration_reason)
      @customer_bonus.destroy!
    end
  end
end
