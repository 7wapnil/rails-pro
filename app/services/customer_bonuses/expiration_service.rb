module CustomerBonuses
  class ExpirationService < ApplicationService
    def initialize(customer_bonus, expiration_reason)
      @customer = customer_bonus.customer
      @customer_bonus = customer_bonus
      @expiration_reason = expiration_reason
    end

    def call
      expire_bonus!
    end

    private

    attr_accessor :customer_bonus, :expiration_reason

    def expire_bonus!
      return @customer_bonus if @customer_bonus.deleted_at

      @customer_bonus.tap do |bonus|
        bonus.update!(expiration_reason: @expiration_reason)
        bonus.destroy!
      end
    end
  end
end
