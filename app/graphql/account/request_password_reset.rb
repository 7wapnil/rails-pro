module Account
  class RequestPasswordReset < ::Base::Resolver
    argument :email, !types.String

    type types.Boolean

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      customer = Customer.find_by(email: args[:email], email_verified: true)
      Account::SendPasswordResetService.call(customer)
      true
    end
  end
end
