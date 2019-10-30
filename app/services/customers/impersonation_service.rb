# frozen_string_literal: true

module Customers
  class ImpersonationService < ApplicationService
    def initialize(user, customer)
      @user = user
      @customer = customer
    end

    def call
      user.log_event(:impersonate_customer, {}, customer)

      "#{ENV['FRONTEND_URL']}/impersonate/#{generate_jwt_token}"
    end

    private

    attr_accessor :customer, :user

    def generate_jwt_token
      JwtService.encode(
        id: customer.id,
        username: customer.username,
        email: customer.email,
        impersonated_by: user.id,
        exp: ENV.fetch('TOKEN_EXPIRATION', 30).to_f.days.from_now.to_i
      )
    end
  end
end
