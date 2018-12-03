module Customers
  class ImpersonationService < ApplicationService
    def initialize(user, customer)
      @user = user
      @customer = customer
    end

    def call
      payload = {
        id: customer.id,
        impersonated_by: user.id,
        email: customer.email,
        username: customer.username
      }
      token = JwtService.encode(payload)
      customer_attrs = payload.slice(:email, :username, :id).to_json

      "#{ENV['IMPERSONATE_CUSTOMER_URL']}#{token}?customer=#{customer_attrs}"
    end

    private

    attr_accessor :customer, :user
  end
end
