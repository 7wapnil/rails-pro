module Customers
  class ImpersonationService < ApplicationService
    def initialize(user, customer)
      @user = user
      @customer = customer
    end

    def call
      payload = customer_payload
      token = JwtService.encode(payload)
      customer_attrs = payload.slice(:email, :username, :id, :wallets).to_json

      "#{ENV['FRONTEND_URL']}/impersonate/#{token}?customer=#{customer_attrs}"
    end

    private

    attr_accessor :customer, :user

    def customer_payload
      {
        id: customer.id,
        impersonated_by: user.id,
        email: customer.email,
        username: customer.username,
        wallets: wallets_payload
      }
    end

    def wallets_payload
      customer.wallets.preload(:currency).map do |wallet|
        {
          id: wallet.id,
          amount: wallet.amount.to_f,
          currency: {
            id: wallet.currency.id,
            code: wallet.currency.code,
            name: wallet.currency.name,
            kind: wallet.currency.kind,
            primary: wallet.currency.primary
          }
        }
      end
    end
  end
end
