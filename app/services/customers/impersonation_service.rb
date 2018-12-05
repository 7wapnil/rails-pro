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

      "#{ENV['FRONTEND_URL']}/impersonate/#{token}?customer=#{customer_attrs}"
    end

    private

    attr_accessor :customer, :user
  end
end
