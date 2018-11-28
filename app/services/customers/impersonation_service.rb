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
      query_params = payload.slice(:email, :username).merge(token: token)

      "#{ENV['FRONTEND_URL']}?#{query_params.to_query(:customer)}"
    end

    private

    attr_accessor :customer, :user
  end
end
