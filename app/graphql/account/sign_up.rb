module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      input = args[:input]
      return unless input
      customer = ::Customers::RegistrationService.call(input.to_h, @request)

      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end
  end
end
