module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def call(_obj, args, _ctx)
      user = Customer.find_for_authentication(username: args[:input][:username])

      if user&.valid_password?(args[:input][:password])
        OpenStruct.new(user: user,
                       token: JwtService.encode(id: user.id,
                                                username: user.username,
                                                email: user.email))
      else
        GraphQL::ExecutionError.new('Wrong email or password')
      end
    end
  end
end
